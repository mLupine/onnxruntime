// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#include "contrib_ops/rocm/bert/gemm_fast_gelu.h"

#include "core/providers/cpu/math/matmul_helper.h"
#include "core/providers/rocm/rocm_common.h"
#include "core/providers/rocm/tunable/gemm_fast_gelu.h"
#include "core/providers/rocm/tunable/gemm_common.h"

using onnxruntime::rocm::ToHipType;
using onnxruntime::rocm::tunable::blas::BlasOp;

namespace onnxruntime {
namespace contrib {
namespace rocm {

#define REGISTER_KERNEL_TYPED(T)                                  \
  ONNX_OPERATOR_TYPED_KERNEL_EX(                                  \
      GemmFastGelu,                                               \
      kMSDomain,                                                  \
      1,                                                          \
      T,                                                          \
      kRocmExecutionProvider,                                     \
      (*KernelDefBuilder::Create())                               \
          .TypeConstraint("T", DataTypeImpl::GetTensorType<T>()), \
      GemmFastGelu<T>);

REGISTER_KERNEL_TYPED(float)
REGISTER_KERNEL_TYPED(MLFloat16)
REGISTER_KERNEL_TYPED(BFloat16)

template <typename T>
Status GemmFastGelu<T>::ComputeInternal(OpKernelContext* ctx) const {
  typedef typename ToHipType<T>::MappedType HipT;

  const auto* X = ctx->Input<Tensor>(0);
  const auto* W = ctx->Input<Tensor>(1);
  const auto* bias = ctx->Input<Tensor>(2);

  bool transa = false;
  bool transb = false;
  bool trans_batch_a = false;
  bool trans_batch_b = false;

  MatMulComputeHelper helper;
  ORT_RETURN_IF_ERROR(helper.Compute(X->Shape(), W->Shape(), transa, transb, trans_batch_a, trans_batch_b, false));

  Tensor* Y = ctx->Output(0, helper.OutputShape());

  // Bail out early if the output is going to be empty
  if (Y->Shape().Size() == 0)
    return Status::OK();

  // gemmfastgelu only support alpha == 1 and beta == 0
  const float alpha = 1.0f;
  const float beta = 0.0f;

  return onnxruntime::rocm::tunable::blas::row_major::GemmFastGelu(
      IsTunableOpEnabled(),
      Stream(), RocblasHandle(),
      transa ? BlasOp::Trans : BlasOp::NonTrans,
      transb ? BlasOp::Trans : BlasOp::NonTrans,
      static_cast<int64_t>(helper.M()), static_cast<int64_t>(helper.N()), static_cast<int64_t>(helper.K()),
      alpha,
      reinterpret_cast<const HipT*>(X->Data<T>()), static_cast<int64_t>(helper.Lda(transa)),
      reinterpret_cast<const HipT*>(W->Data<T>()), static_cast<int64_t>(helper.Ldb(transb)),
      (nullptr != bias) ? reinterpret_cast<const HipT*>(bias->Data<T>()) : nullptr,
      beta,
      reinterpret_cast<HipT*>(Y->MutableData<T>()), static_cast<int64_t>(helper.Ldc()));
}

}  // namespace rocm
}  // namespace contrib
}  // namespace onnxruntime
