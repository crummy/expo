// Copyright 2004-present Facebook. All Rights Reserved.

#pragma once

#include "ABI15_0_0ExecutorToken.h"
#include "ABI15_0_0Executor.h"

namespace facebook {
namespace ReactABI15_0_0 {

/**
 * Class that knows how to create the platform-specific implementation
 * of ExecutorToken.
 */
class ExecutorTokenFactory {
public:
  virtual ~ExecutorTokenFactory() {}

  /**
   * Creates a new ExecutorToken.
   */
  virtual ExecutorToken createExecutorToken() const = 0;
};

} }
