const {onCall} = require("firebase-functions/v2/https");
const {logger} = require("firebase-functions/v2");

//params
const { defineSecret } = require('firebase-functions/params');
const {HttpsError} = require("firebase-functions/v1/auth");
//const projectId = defineString("projectId");
//const storageBucket = defineSecret("storageBucket");
const dexcomClientId = "6sURL7ulvbCpxbm834VOiihS3LZZS7AI";// defineSecret("dexcomClientId");
const dexcomSecret = "xWrHoKuSn9OQm3sF";//defineSecret("dexcomSecret");


let _firestore;
module.exports = {
  init: function(firestore_){
    _firestore = firestore_;
  },
  
  getDexcomToken: onCall( {
    enforceAppCheck: false, // Reject requests with missing or invalid App Check tokens.
  }, async (request) => {
    let code = request.data.code;
    let state = request.data.state;
    const authId = request.auth.uid;

    if( authId != state ){
      throw new HttpsError("invalid-argument", "calling function for wrong user");
    }

    logger.info("Dexcom Token | code=" +code +" | uid=" +authId, {structuredData: true});

    try{
      let host = "https://api.dexcom.com";
      host = "https://sandbox-api.dexcom.com";
      const url = `${host}/v2/oauth2/token`;

      const formData = {
        grant_type: 'authorization_code',
        code: code,
        redirect_uri: 'http://127.0.0.1:43823',
        client_id: dexcomClientId,
        client_secret: dexcomSecret
      };
      console.dir(formData);

      const resp = await fetch(
        url,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded'
          },
          body: new URLSearchParams(formData).toString()
        }
      );

      //console.dir(resp);
      
      if( resp.ok ){
        const data = await resp.json();
        console.log(data);

        const expiresTS = new Date();
        expiresTS.setSeconds(expiresTS.getSeconds() + data.expires_in);

        await _firestore.collection('users').doc(authId).set({
          dexcom: {
            token: data.access_token,
            refresh_token: data.refresh_token,
            token_type: data.token_type,
            token_expires: data.expires_in,
            token_expiresTs: expiresTS,
            login_required: false
          }
        }, {merge: true});

        console.log("User=" +authId +" updated");

        return data.dexcom;
      }else{
        const response = await resp.text();
        logger.error("Error | " +response);
        throw new HttpsError("unknown", `Error | ${response}`);
      }

    }catch(e){
      logger.error(e);
      throw new HttpsError("unknown", `Error | ${e}`);
    }
  }),


  getDexcomReadings: onCall( {
    enforceAppCheck: false, // Reject requests with missing or invalid App Check tokens.
  }, async (request) =>  {
    const uid = request.data.uid;
    const authId = request.auth.uid;

    if( authId != uid ){
      throw new HttpsError("invalid-argument", "calling function for wrong user");
    }
    logger.info("Get Dexcom Reading | uid=" +uid, {structuredData: true});

    const col = await _firestore.collection('users');
    const user = await col.doc(uid).get();
    console.log("Exists:" +user.exists);

    if( !user.exists ){
      throw new HttpsError("not-found", `User not found | uid=${uid}`);
    }

    //url vars
    const now = new Date();
    let startDate = new Date();
    startDate.setDate(now.getDate() - 7);
    startDate = startDate.toISOString().replace(/\..+/, '');
    const endDate = now.toISOString().replace(/\..+/, '');
    //const startDate = dateFormat(Date.UTC(2024,2,1,0,0,0), "yyyy-mm-dd h:MM:ss");
    //const endDate = dateFormat(Date.now(), "yyyy-mm-ddThh:MM:ss");
    const token = user.data().dexcom.token;

    console.log(startDate);
    console.log(endDate);

    //api
    let url = "https://api.dexcom.com";
    url = "https://sandbox-api.dexcom.com";
    url = url +`/v3/users/self/egvs?startDate=${startDate}&endDate=${endDate}`;

    console.log("Token: " +token);
    console.log("Calling: " +url);

    const resp = await fetch(
        url,
        {
          method: 'GET',
          headers: {
            'Authorization': 'Bearer ' +token
          },
        }
    );

    if( resp.ok ) {
      const results = await resp.json();
      return results;
    }else{
      throw new HttpsError("not-found", `User not found | uid=${uid}`);
    }
  }),
}