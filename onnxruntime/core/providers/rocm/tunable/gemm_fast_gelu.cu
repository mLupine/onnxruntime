// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#define _GEMM_FASTGELU_H_KEEP_SIGNATURE_DEFINES
#include "core/providers/rocm/tunable/gemm_fast_gelu.h"

#include <type_traits>
#include <utility>

#include "core/providers/rocm/shared_inc/fpgeneric.h"
#include "core/providers/rocm/tunable/gemm_fast_gelu_tunable.cuh"

namespace onnxruntime {
namespace rocm {
namespace tunable {
namespace blas {

namespace row_major {

template <typename T, typename ScalarT>
inline GEMMFASTGELU(T, ScalarT) {
  GemmFastGeluParams<T> params;
  params.stream = stream;
  params.handle = handle;

  params.opa = opa;
  params.opb = opb;
  params.m = m;
  params.n = n;
  params.k = k;
  if constexpr (!std::is_same_v<T, ScalarT> && std::is_same_v<ScalarT, float>) {
    params.alpha = ToHipType<T>::FromFloat(std::forward<T>(alpha));
  } else {
    params.alpha = alpha;
  }
  params.a = a;
  params.lda = lda;
  params.b = b;
  params.ldb = ldb;
  params.bias = bias;
  if constexpr (!std::is_same_v<T, ScalarT> && std::is_same_v<ScalarT, float>) {
    params.beta = ToHipType<T>::FromFloat(std::forward<T>(beta));
  } else {
    params.beta = beta;
  }
  params.c = c;
  params.ldc = ldc;

  if (tunable) {
    params.tuning = true;
    if (opa == BlasOp::N && opb == BlasOp::N) {
      static internal::GemmFastGeluTunableOp<T, internal::Row, internal::Row> gemm_fast_gelu{};
      gemm_fast_gelu.EnableTuning();
      return gemm_fast_gelu(&params);
    } else if (opa == BlasOp::T && opb == BlasOp::N) {
      static internal::GemmFastGeluTunableOp<T, internal::Col, internal::Row> gemm_fast_gelu{};
      gemm_fast_gelu.EnableTuning();
      return gemm_fast_gelu(&params);
    } else if (opa == BlasOp::N && opb == BlasOp::T) {
      static internal::GemmFastGeluTunableOp<T, internal::Row, internal::Col> gemm_fast_gelu{};
      gemm_fast_gelu.EnableTuning();
      return gemm_fast_gelu(&params);
    } else /*if (opa == BlasOp::T && opb == BlasOp::T)*/ {
      static internal::GemmFastGeluTunableOp<T, internal::Col, internal::Col> gemm_fast_gelu{};
      gemm_fast_gelu.EnableTuning();
      return gemm_fast_gelu(&params);
    }
  }

  return internal::GemmFastGeluUnfused(&params);
}

#define CALL_GEMMFASTGELU(T, ScalarT)                   \
  GemmFastGelu<T, ScalarT>(tunable, stream, handle,     \
                           opa, opb,                    \
                           m, n, k,                     \
                           alpha, a, lda, b, ldb, bias, \
                           beta, c, ldc)

// clang-format off
GEMMFASTGELU(double,   double  ) { return CALL_GEMMFASTGELU(double,   double  ); }
GEMMFASTGELU(float,    float   ) { return CALL_GEMMFASTGELU(float,    float   ); }
GEMMFASTGELU(half,     half    ) { return CALL_GEMMFASTGELU(half,     half    ); }
GEMMFASTGELU(BFloat16, BFloat16) { return CALL_GEMMFASTGELU(BFloat16, BFloat16); }
GEMMFASTGELU(double,   float   ) { return CALL_GEMMFASTGELU(double,   float   ); }
GEMMFASTGELU(half,     float   ) { return CALL_GEMMFASTGELU(half,     float   ); }
GEMMFASTGELU(BFloat16, float   ) { return CALL_GEMMFASTGELU(BFloat16, float   ); }
// clang-format on

#undef CALL_GEMM

}  // namespace row_major

namespace column_major {

#define CALL_GEMM_FASTGELU_WITH_AB_SWAPPED(T, ScalarT)             \
  row_major::GemmFastGelu<T, ScalarT>(tunable, stream, handle,     \
                                      opb, opa,                    \
                                      n, m, k,                     \
                                      alpha, b, ldb, a, lda, bias, \
                                      beta, c, ldc)

// clang-format off
GEMMFASTGELU(double,   double  ) { return CALL_GEMM_FASTGELU_WITH_AB_SWAPPED(double,   double  ); }
GEMMFASTGELU(float,    float   ) { return CALL_GEMM_FASTGELU_WITH_AB_SWAPPED(float,    float   ); }
GEMMFASTGELU(half,     half    ) { return CALL_GEMM_FASTGELU_WITH_AB_SWAPPED(half,     half    ); }
GEMMFASTGELU(BFloat16, BFloat16) { return CALL_GEMM_FASTGELU_WITH_AB_SWAPPED(BFloat16, BFloat16); }
GEMMFASTGELU(double,   float   ) { return CALL_GEMM_FASTGELU_WITH_AB_SWAPPED(double,   float   ); }
GEMMFASTGELU(half,     float   ) { return CALL_GEMM_FASTGELU_WITH_AB_SWAPPED(half,     float   ); }
GEMMFASTGELU(BFloat16, float   ) { return CALL_GEMM_FASTGELU_WITH_AB_SWAPPED(BFloat16, float   ); }
// clang-format on

#undef CALL_GEMM_FASTGELU_WITH_AB_SWAPPED

}  // namespace column_major

}  // namespace blas
}  // namespace tunable
}  // namespace rocm
}  // namespace onnxruntime
