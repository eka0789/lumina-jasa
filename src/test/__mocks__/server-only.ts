// Mock for 'server-only' package in Vitest test environment.
// The real package throws at import time in non-server environments.
// In tests we simply allow the import without throwing.
export {}
