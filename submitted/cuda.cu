#include "cuda.cuh"

namespace {

constexpr int GLIDER_MASK_COUNT = 16;

__device__ __constant__ unsigned int DEVICE_GLIDER_MASKS[GLIDER_MASK_COUNT] = {
    0x01D, 0x116, 0x170, 0x0D1,
    0x035, 0x053, 0x158, 0x194,
    0x14A, 0x063, 0x0A5, 0x18C,
    0x162, 0x10E, 0x08D, 0x0E1
};

inline size_t histogramReturnLength(const int bin_width) {
    return (HISTOGRAM_MAX_VALUE + static_cast<size_t>(bin_width) - 1u) / static_cast<size_t>(bin_width);
}

inline int blocksForWork(const size_t work_items, const int threads_per_block) {
    size_t blocks = (work_items + static_cast<size_t>(threads_per_block) - 1u) / static_cast<size_t>(threads_per_block);
    if (blocks < 1u) {
        blocks = 1u;
    }
    if (blocks > 4096u) {
        blocks = 4096u;
    }
    return static_cast<int>(blocks);
}

__device__ unsigned int buildDeviceCellMask(const unsigned char *cells, const size_t width, const size_t x, const size_t y) {
    unsigned int mask = 0;
    for (int gy = 0; gy < 3; ++gy) {
        for (int gx = 0; gx < 3; ++gx) {
            if (cells[(y + static_cast<size_t>(gy)) * width + x + static_cast<size_t>(gx)]) {
                mask |= 1u << (gy * 3 + gx);
            }
        }
    }
    return mask;
}

__device__ bool isDeviceGliderMask(const unsigned int mask) {
    for (int i = 0; i < GLIDER_MASK_COUNT; ++i) {
        if (mask == DEVICE_GLIDER_MASKS[i]) {
            return true;
        }
    }
    return false;
}

__global__ void countGlidersKernel(const unsigned char *cells, const size_t width, const size_t height, unsigned long long *count_out) {
    extern __shared__ unsigned long long block_counts[];

    const size_t window_width = width - 2u;
    const size_t window_height = height - 2u;
    const size_t window_count = window_width * window_height;
    const size_t global_thread = static_cast<size_t>(blockIdx.x) * blockDim.x + threadIdx.x;
    const size_t stride = static_cast<size_t>(gridDim.x) * blockDim.x;

    unsigned long long local_count = 0;
    for (size_t i = global_thread; i < window_count; i += stride) {
        const size_t x = i % window_width;
        const size_t y = i / window_width;
        const unsigned int mask = buildDeviceCellMask(cells, width, x, y);
        if (isDeviceGliderMask(mask)) {
            ++local_count;
        }
    }

    block_counts[threadIdx.x] = local_count;
    __syncthreads();

    for (unsigned int offset = blockDim.x / 2u; offset > 0u; offset >>= 1u) {
        if (threadIdx.x < offset) {
            block_counts[threadIdx.x] += block_counts[threadIdx.x + offset];
        }
        __syncthreads();
    }

    if (threadIdx.x == 0) {
        atomicAdd(count_out, block_counts[0]);
    }
}

__global__ void histogramKernel(const int *numbers, const size_t length, const int bin_width, int *bins, const size_t storage_len) {
    extern __shared__ int shared_bins[];

    for (size_t bin = threadIdx.x; bin < storage_len; bin += blockDim.x) {
        shared_bins[bin] = 0;
    }
    __syncthreads();

    const size_t global_thread = static_cast<size_t>(blockIdx.x) * blockDim.x + threadIdx.x;
    const size_t stride = static_cast<size_t>(gridDim.x) * blockDim.x;
    for (size_t i = global_thread; i < length; i += stride) {
        const int bin = numbers[i] / bin_width;
        if (bin >= 0 && static_cast<size_t>(bin) < storage_len) {
            atomicAdd(&shared_bins[bin], 1);
        }
    }
    __syncthreads();

    for (size_t bin = threadIdx.x; bin < storage_len; bin += blockDim.x) {
        atomicAdd(&bins[bin], shared_bins[bin]);
    }
}

__device__ float embossKernelValue(const int ky, const int kx) {
    if (ky == 0) {
        return (kx == 0) ? -2.0f : ((kx == 1) ? -1.0f : 0.0f);
    }
    if (ky == 1) {
        return (kx == 0) ? -1.0f : ((kx == 1) ? 0.0f : 1.0f);
    }
    return (kx == 0) ? 0.0f : ((kx == 1) ? 1.0f : 2.0f);
}

__device__ float rgbToGrey(const unsigned char R, const unsigned char G, const unsigned char B) {
    return (0.2126f * R) + (0.7152f * G) + (0.0722f * B);
}

__global__ void embossKernel(const unsigned char *pixels, const size_t width, const size_t height, unsigned char *output) {
    const size_t x = static_cast<size_t>(blockIdx.x) * blockDim.x + threadIdx.x;
    const size_t y = static_cast<size_t>(blockIdx.y) * blockDim.y + threadIdx.y;
    const size_t out_width = width - 2u;
    const size_t out_height = height - 2u;

    if (x >= out_width || y >= out_height) {
        return;
    }

    float pixel_sum = 0.0f;
    for (int kx = 0; kx < 3; ++kx) {
        for (int ky = 0; ky < 3; ++ky) {
            const size_t offset = (width * (y + static_cast<size_t>(ky)) + x + static_cast<size_t>(kx)) * 3u;
            const unsigned char R = pixels[offset + 0u];
            const unsigned char G = pixels[offset + 1u];
            const unsigned char B = pixels[offset + 2u];
            pixel_sum += rgbToGrey(R, G, B) * embossKernelValue(ky, kx);
        }
    }

    pixel_sum += 128.0f;
    pixel_sum = pixel_sum < 0.0f ? 0.0f : pixel_sum;
    pixel_sum = pixel_sum > 255.0f ? 255.0f : pixel_sum;
    output[(out_width * y) + x] = static_cast<unsigned char>(pixel_sum);
}

}

uint64_t cuda_countGliders(const unsigned char *cells, const size_t width, const size_t height) {
    if (width < 3 || height < 3) {
        return 0;
    }

    const size_t input_bytes = width * height * sizeof(unsigned char);
    const size_t window_count = (width - 2u) * (height - 2u);
    const int threads_per_block = 256;
    const int blocks = blocksForWork(window_count, threads_per_block);

    unsigned char *device_cells = nullptr;
    unsigned long long *device_count = nullptr;
    unsigned long long host_count = 0;

    CUDA_CALL(cudaMalloc(reinterpret_cast<void**>(&device_cells), input_bytes));
    CUDA_CALL(cudaMalloc(reinterpret_cast<void**>(&device_count), sizeof(unsigned long long)));
    CUDA_CALL(cudaMemcpy(device_cells, cells, input_bytes, cudaMemcpyHostToDevice));
    CUDA_CALL(cudaMemset(device_count, 0, sizeof(unsigned long long)));

    countGlidersKernel<<<blocks, threads_per_block, threads_per_block * sizeof(unsigned long long)>>>(device_cells, width, height, device_count);
    CUDA_CHECK();

    CUDA_CALL(cudaMemcpy(&host_count, device_count, sizeof(unsigned long long), cudaMemcpyDeviceToHost));
    CUDA_CALL(cudaFree(device_count));
    CUDA_CALL(cudaFree(device_cells));

    return static_cast<uint64_t>(host_count);
}

size_t cuda_histogram(const int *numbers, size_t length, int bin_width, int *output) {
    if (bin_width <= 0) {
        return 0;
    }

    const size_t histogram_len = histogramReturnLength(bin_width);
    const size_t storage_len = (HISTOGRAM_MAX_VALUE / static_cast<size_t>(bin_width)) + 1u;
    const int threads_per_block = 256;
    const int blocks = blocksForWork(length, threads_per_block);

    int *device_numbers = nullptr;
    int *device_bins = nullptr;

    if (length > 0u) {
        CUDA_CALL(cudaMalloc(reinterpret_cast<void**>(&device_numbers), length * sizeof(int)));
        CUDA_CALL(cudaMemcpy(device_numbers, numbers, length * sizeof(int), cudaMemcpyHostToDevice));
    }
    CUDA_CALL(cudaMalloc(reinterpret_cast<void**>(&device_bins), storage_len * sizeof(int)));
    CUDA_CALL(cudaMemset(device_bins, 0, storage_len * sizeof(int)));

    histogramKernel<<<blocks, threads_per_block, storage_len * sizeof(int)>>>(device_numbers, length, bin_width, device_bins, storage_len);
    CUDA_CHECK();

    CUDA_CALL(cudaMemcpy(output, device_bins, histogram_len * sizeof(int), cudaMemcpyDeviceToHost));
    CUDA_CALL(cudaFree(device_bins));
    if (device_numbers) {
        CUDA_CALL(cudaFree(device_numbers));
    }

    return histogram_len;
}

void cuda_emboss(const unsigned char *pixels, const size_t width, const size_t height, unsigned char *output) {
    if (width < 3 || height < 3) {
        return;
    }

    const size_t out_width = width - 2u;
    const size_t out_height = height - 2u;
    const size_t input_bytes = width * height * 3u * sizeof(unsigned char);
    const size_t output_bytes = out_width * out_height * sizeof(unsigned char);

    unsigned char *device_pixels = nullptr;
    unsigned char *device_output = nullptr;

    CUDA_CALL(cudaMalloc(reinterpret_cast<void**>(&device_pixels), input_bytes));
    CUDA_CALL(cudaMalloc(reinterpret_cast<void**>(&device_output), output_bytes));
    CUDA_CALL(cudaMemcpy(device_pixels, pixels, input_bytes, cudaMemcpyHostToDevice));

    const dim3 threads_per_block(16, 16);
    const dim3 blocks(
        static_cast<unsigned int>((out_width + threads_per_block.x - 1u) / threads_per_block.x),
        static_cast<unsigned int>((out_height + threads_per_block.y - 1u) / threads_per_block.y)
    );

    embossKernel<<<blocks, threads_per_block>>>(device_pixels, width, height, device_output);
    CUDA_CHECK();

    CUDA_CALL(cudaMemcpy(output, device_output, output_bytes, cudaMemcpyDeviceToHost));
    CUDA_CALL(cudaFree(device_output));
    CUDA_CALL(cudaFree(device_pixels));
}
