#include "openmp.h"
#include <omp.h>

#include <stdlib.h>
#include <string.h>

#define GLIDER_MASK_COUNT 16

static const unsigned int GLIDER_MASKS[GLIDER_MASK_COUNT] = {
    0x01D, 0x116, 0x170, 0x0D1,
    0x035, 0x053, 0x158, 0x194,
    0x14A, 0x063, 0x0A5, 0x18C,
    0x162, 0x10E, 0x08D, 0x0E1
};

static int isGliderMask(const unsigned int mask) {
    for (int i = 0; i < GLIDER_MASK_COUNT; ++i) {
        if (mask == GLIDER_MASKS[i]) {
            return 1;
        }
    }
    return 0;
}

static unsigned int buildCellMask(const unsigned char *cells, const size_t width, const size_t x, const size_t y) {
    unsigned int mask = 0;
    for (int gy = 0; gy < 3; ++gy) {
        for (int gx = 0; gx < 3; ++gx) {
            if (cells[(y + (size_t)gy) * width + x + (size_t)gx]) {
                mask |= 1u << (gy * 3 + gx);
            }
        }
    }
    return mask;
}

static size_t histogramReturnLength(const int bin_width) {
    return (HISTOGRAM_MAX_VALUE + (size_t)bin_width - 1u) / (size_t)bin_width;
}

uint64_t openmp_countGliders(const unsigned char *cells, const size_t width, const size_t height) {
    if (width < 3 || height < 3) {
        return 0;
    }

    const size_t window_width = width - 2;
    const size_t window_height = height - 2;
    const size_t window_count = window_width * window_height;
    const long long signed_window_count = (long long)window_count;
    long long window_index;
    uint64_t count = 0;

#pragma omp parallel for reduction(+:count) schedule(static)
    for (window_index = 0; window_index < signed_window_count; ++window_index) {
        const size_t i = (size_t)window_index;
        const size_t x = i % window_width;
        const size_t y = i / window_width;
        const unsigned int mask = buildCellMask(cells, width, x, y);
        if (isGliderMask(mask)) {
            ++count;
        }
    }

    return count;
}

size_t openmp_histogram(const int *numbers, size_t length, int bin_width, int *output) {
    if (bin_width <= 0) {
        return 0;
    }

    const size_t histogram_len = histogramReturnLength(bin_width);
    const size_t storage_len = (HISTOGRAM_MAX_VALUE / (size_t)bin_width) + 1u;
    memset(output, 0, sizeof(int) * histogram_len);

    const int thread_count = omp_get_max_threads();
    int *local_histograms = (int*)calloc((size_t)thread_count * storage_len, sizeof(int));
    if (!local_histograms) {
        for (size_t i = 0; i < length; ++i) {
            const int bin = numbers[i] / bin_width;
            if (bin >= 0 && (size_t)bin < histogram_len) {
                ++output[bin];
            }
        }
        return histogram_len;
    }

    {
        long long i;

#pragma omp parallel
        {
            const int thread_id = omp_get_thread_num();
            int *local_histogram = local_histograms + ((size_t)thread_id * storage_len);

#pragma omp for schedule(static)
            for (i = 0; i < (long long)length; ++i) {
                const int bin = numbers[(size_t)i] / bin_width;
                if (bin >= 0 && (size_t)bin < storage_len) {
                    ++local_histogram[bin];
                }
            }
        }
    }

    {
        long long bin;

#pragma omp parallel for schedule(static)
        for (bin = 0; bin < (long long)histogram_len; ++bin) {
            int total = 0;
            for (int thread_id = 0; thread_id < thread_count; ++thread_id) {
                total += local_histograms[((size_t)thread_id * storage_len) + (size_t)bin];
            }
            output[(size_t)bin] = total;
        }
    }

    free(local_histograms);
    return histogram_len;
}

void openmp_emboss(const unsigned char *pixels, const size_t width, const size_t height, unsigned char* output) {
    if (width < 3 || height < 3) {
        return;
    }

    const long long out_width = (long long)(width - 2);
    const long long out_height = (long long)(height - 2);
    long long y;
    long long x;

#pragma omp parallel for collapse(2) schedule(static)
    for (y = 0; y < out_height; ++y) {
        for (x = 0; x < out_width; ++x) {
            float pixel_sum = 0.0f;

            for (int kx = 0; kx < 3; ++kx) {
                for (int ky = 0; ky < 3; ++ky) {
                    const size_t offset = ((size_t)width * ((size_t)y + (size_t)ky) + (size_t)x + (size_t)kx) * 3u;
                    const unsigned char R = pixels[offset + 0u];
                    const unsigned char G = pixels[offset + 1u];
                    const unsigned char B = pixels[offset + 2u];
                    const float grey_pixel = (0.2126f * R) + (0.7152f * G) + (0.0722f * B);

                    float kernel_value = 0.0f;
                    if (ky == 0) {
                        kernel_value = (kx == 0) ? -2.0f : ((kx == 1) ? -1.0f : 0.0f);
                    } else if (ky == 1) {
                        kernel_value = (kx == 0) ? -1.0f : ((kx == 1) ? 0.0f : 1.0f);
                    } else {
                        kernel_value = (kx == 0) ? 0.0f : ((kx == 1) ? 1.0f : 2.0f);
                    }

                    pixel_sum += grey_pixel * kernel_value;
                }
            }

            pixel_sum += 128.0f;
            pixel_sum = pixel_sum < 0.0f ? 0.0f : pixel_sum;
            pixel_sum = pixel_sum > 255.0f ? 255.0f : pixel_sum;
            output[((size_t)out_width * (size_t)y) + (size_t)x] = (unsigned char)pixel_sum;
        }
    }
}
