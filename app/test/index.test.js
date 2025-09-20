const request = require("supertest");
const { app, server } = require("../index");

let appServer;

afterEach(async () => {
  if (appServer && appServer.close) {
    await new Promise((resolve) => appServer.close(resolve));
  }
});

describe("Server Tests", () => {
  test("GET / responds with Hello message", async () => {
    appServer = await server.start(3001);
    const res = await request(appServer).get("/");
    expect(res.statusCode).toBe(200);
    expect(res.text).toContain("Hello from DevSecOps App 🚀");
  });

  test("GET /health returns healthy status when system is healthy", async () => {
    appServer = await server.start(3002);
    const res = await request(appServer).get("/health");
    expect(res.statusCode).toBe(200);
    expect(res.body).toEqual({ status: "healthy" });
  });

  test("GET /health returns unhealthy status when system check fails", async () => {
    appServer = await server.start(3003);
    await request(appServer).post("/toggle-health").send({ healthy: false });
    const res = await request(appServer).get("/health");
    expect(res.statusCode).toBe(500);
    expect(res.body).toEqual({ status: "unhealthy" });
  });

  describe("Server Start", () => {
    test("starts with valid custom port", async () => {
      appServer = await server.start(4000);
      expect(appServer.listening).toBe(true);
    });

    test.each([
      "abc",
      -1,
      0,
      70000,
      3.14,
      null,
      undefined,
      {},
      [],
    ])("throws error for invalid port: %p", (invalidPort) => {
      expect(() => server.start(invalidPort)).toThrow("Invalid port number");
    });
  });
});
