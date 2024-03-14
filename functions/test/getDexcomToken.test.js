// initialize test database
import {getDexcomToken} from "../index";

process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";


import admin from 'firebase-admin';
const { logger } = require("firebase-functions");
const fbTest = require("firebase-functions-test");
import {describe, expect, jest, test} from '@jest/globals';
const {wrap, firestore} = fbTest({});



const {getDexcomReadings} = require("../index");


describe("firebase-functions-test", () => {
    describe("#getDexcomReadings", () => {

        test("invoked and returns with no errors", async () => {
            //.useEmulator("127.0.0.1", 5001);
            const wrappedFunction = wrap(getDexcomToken);
            const result = await wrappedFunction({"data": {
                    "code": "533d33c28705a6c8f06c2a3fde87da30",
                    "state": "qOvGYUB5NIHyPRGpEtP3Yhka43WA"
                }, "auth": {
                    "uid": "qOvGYUB5NIHyPRGpEtP3Yhka43WA"
                }
            });
            expect(result).toBe("ok");
        });

    });
});
