module.exports = {
  testEnvironment: "node", // ensures proper async/timers handling
  forceExit: true,         // force exit after all tests (safety net)
  detectOpenHandles: true  // explicitly detect leaks
};
