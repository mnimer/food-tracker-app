const { logger } = require("firebase-functions");
const fbTest = require("firebase-functions-test");
const {health} = require("../index");
import {describe, expect, jest, test} from '@jest/globals';
const {wrap} = fbTest();

describe("firebase-functions-test", () => {
    describe("#health", () => {
        test("invoked and returns 'ok'", async () => {
            const wrappedFunction = wrap(health);
            const result = await wrappedFunction("");
            expect(result).toBe("ok");
        });

        test("will log when the v2 cloud function is invoked", async () => {
            const logSpy = jest.spyOn(logger, "debug");

            const wrappedFunction = wrap(health);
            const result = await wrappedFunction();
            expect(logSpy).toHaveBeenCalled();
        });
    });
});