#include "daw_with_ffi.h"
#include <math.h>
#include <string.h>

/* see constants.dart */
#define DAW_SAMPLE_RATE_HZ 44100
#define NR_NOTES 25
#define STEP_DURATION_MS 50
#define MAX_NR_STEPS 12000

#define NR_SAMPLES_PER_STEP (DAW_SAMPLE_RATE_HZ * STEP_DURATION_MS / 1000)
#define NR_SAMPLES_IN_TRACK (NR_SAMPLES_PER_STEP * MAX_NR_STEPS)
#define WAV_HEADER_SIZE 44

/* https://ccrma.stanford.edu/courses/422-winter-2014/projects/WaveFormat/ */
const uint8_t wav_header[] = {
      0x52,0x49,0x46,0x46,
      0x24,0x08,0x00,0x00,
      0x57,0x41,0x56,0x45,
      0x66,0x6d,0x74,0x20,
      0x10,0x00,0x00,0x00,
      0x01,0x00,0x01,0x00,
      0x44,0xac,0x00,0x00,
      0x88,0x58,0x01,0x00,
      0x02,0x00,0x10,0x00,
      0x64,0x61,0x74,0x61,
      0xc0,0x7e,0x27,0x03,
};

FFI_PLUGIN_EXPORT int export_wav(uint8_t const* const* restrict wav_srcs,
                                 uint64_t const* restrict src_lengths,
                                 uint8_t const* const* restrict played_arr,
                                 uint64_t const* restrict played_lengths,
                                 uint64_t nr_tracks_64,
                                 uint8_t* restrict wav_out) {
  /* sanity check */
  if (!nr_tracks_64 || !wav_srcs       || !src_lengths ||
      !played_arr   || !played_lengths || !wav_out) {
    return 0;
  }

  /* endianness check */
  uint32_t tmp = 1;
  if (*(char*)&tmp != 1) {
    /* not little endian */
    return 0;
  }

  size_t nr_tracks = nr_tracks_64;
  
  /* prepare wav file */
  memset(wav_out, 0, WAV_HEADER_SIZE + 2 * NR_SAMPLES_IN_TRACK);
  memcpy(wav_out, wav_header, WAV_HEADER_SIZE);

  /* precompute pitches */
  double factors[NR_NOTES];
  for (int_fast32_t i = 0; i < NR_NOTES; ++i) {
    int_fast32_t lvl = i - NR_NOTES / 2;
    factors[i] = exp(lvl / 12.0 / log(2));
  }

  /* mix each track */
  for (size_t i = 0; i < nr_tracks; ++i) {
    uint8_t const* const restrict wav_src = wav_srcs[i];

    /* sanity check */
    if (!wav_src || !played_arr[i]) {
      return 0;
    }

    /* calculating data offset */
    uint_fast64_t offset = WAV_HEADER_SIZE;
    uint_fast64_t extra_offset = 0;
    while (wav_src[36 + extra_offset] != 'd' || wav_src[37 + extra_offset] != 'a' ||
           wav_src[38 + extra_offset] != 't' || wav_src[39 + extra_offset] != 'a') {
      
      /* add 2 to preserve 2-byte alignment */
      extra_offset += 2;
      if (39 + extra_offset >= src_lengths[i]) {
        return 0;
      }
    }
    offset += extra_offset;

    /* extracting data from source files */
    uint_fast16_t nr_channels;
    uint_fast32_t src_rate;
    uint_fast16_t bytes_per_sample;
    uint_fast32_t nr_src_samples;
    {
      uint16_t const* restrict nr_channels_ptr = (uint16_t const*)&wav_src[22];
      uint32_t const* restrict src_rate_ptr = (uint32_t const*)&wav_src[24];
      uint16_t const* restrict bytes_per_sample_ptr = (uint16_t const*)&wav_src[34];
      uint32_t const* restrict nr_src_samples_ptr = (uint32_t const*)&wav_src[40 + extra_offset];
      nr_channels = *nr_channels_ptr;
      src_rate = *src_rate_ptr;
      bytes_per_sample = *bytes_per_sample_ptr;
      nr_src_samples = *nr_src_samples_ptr;
    }

    bytes_per_sample /= 8;
    nr_src_samples /= nr_channels * bytes_per_sample;

    /* only accept tracks with 16 bits per sample */
    if (bytes_per_sample != 2) {
      continue;
    }

    /* for each note in step */
    for (uint64_t j = 0; j < played_lengths[i]; ++j) {
      for (uint_fast64_t k = 0; k < NR_NOTES; ++k) {
        uint8_t const* restrict played_in_track = played_arr[i];

        /* if played */
        if (played_in_track[j*NR_NOTES+k]) {
          int_fast64_t lvl = k;
          lvl -= NR_NOTES / 2;
          double factor = factors[k];

          double dst_rate = DAW_SAMPLE_RATE_HZ;
          double src_rate_p = src_rate * factor;
          
          /* nr of samples to modify */
          uint_fast64_t nr_dst_samples = nr_src_samples * dst_rate / src_rate_p;

          /* preventing out-of-boundary error */
          uint_fast64_t max_l_xcl = nr_dst_samples;
          uint_fast64_t nr_next_samples = NR_SAMPLES_IN_TRACK - j * NR_SAMPLES_PER_STEP;
          if (max_l_xcl > nr_next_samples) {
            max_l_xcl = nr_next_samples;
          }

          /* for each destination sample */
          for (uint_fast64_t l = 0; l < max_l_xcl; ++l) {
            
            /* interpolation to source */
            uint_fast64_t src_index = l * src_rate_p / dst_rate;
            uint16_t* restrict sample_ptr =
              (uint16_t*)&wav_out[WAV_HEADER_SIZE + (j * NR_SAMPLES_PER_STEP + l) * 2];
            int_fast32_t sample = *sample_ptr;
            
            /* make signed */
            if (sample >= 0x8000) {
              sample -= 0x10000;
            }

            /* add to sample */
            if (bytes_per_sample == 2) {
              uint16_t* restrict src_sample_ptr = (uint16_t*)&wav_src[offset + 
                  src_index * nr_channels * bytes_per_sample];
              int_fast32_t src_sample = *src_sample_ptr;
             
              /* make signed */
              if (src_sample >= 0x8000) {
                src_sample -= 0x10000;
              }

              sample += src_sample;
            }

            /* clamp */
            if (sample < -0x8000) {
              sample = -0x8000;
            }
            if (sample >= 0x8000) {
              sample = 0x7fff;
            }

            /* make 2's complement */
            if (sample < 0) {
              sample += 0x10000;
            }

            *sample_ptr = (uint_fast32_t)sample;
          }
        }
      }
    }
  }

  return 1;
}