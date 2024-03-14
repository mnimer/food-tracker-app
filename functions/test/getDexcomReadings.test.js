// initialize test database
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";


import admin from 'firebase-admin';
const { logger } = require("firebase-functions");
const fbTest = require("firebase-functions-test");
import {describe, expect, jest, test} from '@jest/globals';
import sinon from "sinon";
const {wrap, firestore} = fbTest({});



const {getDexcomReadings} = require("../index");


describe("firebase-functions-test", () => {
    describe("#getDexcomReadings", () => {

        test("invoked and returns with no errors", async () => {
            //.useEmulator("127.0.0.1", 5001);
            const wrappedFunction = wrap(getDexcomReadings);
            const result = await wrappedFunction({"data": {
                    "uid": "qOvGYUB5NIHyPRGpEtP3Yhka43WA"
                }, "auth": {
                    "uid": "qOvGYUB5NIHyPRGpEtP3Yhka43WA"
                }
            });
            expect(result.uid).toBe("qOvGYUB5NIHyPRGpEtP3Yhka43WA");
            //expect(result.records).toBeGreaterThan(0);
        });

        /**
         * Test Error States
         */

        test("mismatch user error", async () => {
            //.useEmulator("127.0.0.1", 5001);
            try {
                const wrappedFunction = wrap(getDexcomReadings);
                const result = await wrappedFunction({
                    "data": {
                        "uid": "qOvGYUB5NIHyPRGpEtP3Yhka43WA"
                    }, "auth": {
                        "uid": "qOvGYUB6HHHyPRGpEtP3Yhka44WBV"
                    }
                });
                throw Error("Should throw exception");
            }catch (err) {
                expect(err.code).toBe("invalid-argument");
            }
        });

        test("user not found error", async () => {
            //.useEmulator("127.0.0.1", 5001);
            try {
                const wrappedFunction = wrap(getDexcomReadings);
                const result = await wrappedFunction({
                    "data": {
                        "uid": "qOvGYUB6HHHyPRGpEtP3Yhka44WBV"
                    }, "auth": {
                        "uid": "qOvGYUB6HHHyPRGpEtP3Yhka44WBV"
                    }
                });
                throw Error("Should throw exception");
            }catch (err) {
                expect(err.code).toBe("not-found");
            }
        });

        test("user not logged into dexcom error", async () => {
            //.useEmulator("127.0.0.1", 5001);
            try {
                const wrappedFunction = wrap(getDexcomReadings);
                const result = await wrappedFunction({
                    "data": {
                        "uid": "u5CYgKRaMxPL0bd7Ir17"
                    }, "auth": {
                        "uid": "u5CYgKRaMxPL0bd7Ir17"
                    }
                });
                throw Error("Should throw exception");
            }catch (err) {
                expect(err.code).toBe("cancelled");
            }
        });
    });
});
