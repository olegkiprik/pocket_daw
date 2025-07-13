#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#if _WIN32
#include <windows.h>
#else
#include <pthread.h>
#include <unistd.h>
#endif

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

/* Export an audio file that was created in DAW
 *
 * wav_srcs        Source .wav audio files contents,
 *                 all pointers have 2-byte alignment
 *
 * src_lengths     Source audio files lengths
 * played_arr      Played notes in each step
 * played_lenghts  Number of steps for each track
 * nr_tracks       Number of tracks
 *
 * wav_out         Output .wav audio file contents,
 *                 preallocation and 2-byte alignment required
 */
FFI_PLUGIN_EXPORT int export_wav(uint8_t const* const* restrict wav_srcs,
                                 uint64_t const* restrict src_lengths,
                                 uint8_t const* const* restrict played_arr,
                                 uint64_t const* restrict played_lengths,
                                 uint64_t nr_tracks,
                                 uint8_t* restrict wav_out);
