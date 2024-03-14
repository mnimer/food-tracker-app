const {onCall} = require("firebase-functions/v2/https");
const {logger} = require("firebase-functions/v2");

//params
const { defineSecret } = require('firebase-functions/params');
const {HttpsError} = require("firebase-functions/v1/auth");
//const projectId = defineString("projectId");
//const storageBucket = defineSecret("storageBucket");
const dexcomClientId = "6sURL7ulvbCpxbm834VOiihS3LZZS7AI";// defineSecret("dexcomClientId");
const dexcomSecret = "xWrHoKuSn9OQm3sF";//defineSecret("dexcomSecret");




const refreshToken = async function(token) {
  //const host = "https://api.dexcom.com";
  const host = "https://sandbox-api.dexcom.com";
  const url = `${host}/v2/oauth2/token`;

  const formData = {
    grant_type: 'refresh_token',
    client_id: dexcomClientId,
    client_secret: dexcomSecret,
    refresh_token: token
  }

  const response = await fetch(
      url,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: new URLSearchParams(formData).toString()
      }
  );

  if( response.status == 200) {
    const json = await response.json();
    return json.access_token;
  }else{
    throw new Error("Invalid request");
  }
};

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
    let recordCount = 0;
    const uid = request.data.uid;
    const authId = request.auth.uid;

    if( authId != uid ){
      throw new HttpsError("invalid-argument", "calling function for wrong user");
    }
    logger.info("Get Dexcom Reading | uid=" +uid, {structuredData: true});

    //Get current user, to pull dexcom token
    const user = await _firestore.collection('users').doc(uid).get();

    if( !user.exists ){
      throw new HttpsError("not-found", `User not found | uid=${uid}`);
    }

    if( user.data().dexcom == null ){
      throw new HttpsError("cancelled", `User not authenticated with dexcom yet | uid=${uid}`);
    }


    //url vars
    const now = new Date();
    let startDate = new Date();
    startDate.setDate(now.getDate() - 2);

    //Get last TS in DB for user log
    const currentUser = await _firestore.collection("cgm_logs").doc(uid).get();
    logger.debug(`uid=${uid} | exists:${currentUser.exists}`);

    const currentUserLog = await  _firestore.collection("cgm_logs").doc(uid).collection("sensor_readings").orderBy("systemTime", "desc").limit(1).get();
    logger.debug(`uid=${uid} | exists:${currentUserLog.docs.length}`);

    if(currentUserLog.docs.length > 0){
      const dt = new Date();
      dt.setTime(currentUserLog.docs[0].data().systemTime);
      startDate = dt;
      logger.debug(`Last user TS: ${dt.toUTCString()}`);
    }


    startDate = startDate.toISOString().replace(/\..+/, '');
    const endDate = now.toISOString().replace(/\..+/, '');
    //const startDate = dateFormat(Date.UTC(2024,2,1,0,0,0), "yyyy-mm-dd h:MM:ss");
    //const endDate = dateFormat(Date.now(), "yyyy-mm-ddThh:MM:ss");
    let token = user.data().dexcom.token;



    //api
    let host = "https://api.dexcom.com";
    host = "https://sandbox-api.dexcom.com";
    const apiUrl = `${host}/v3/users/self/egvs?startDate=${startDate}&endDate=${endDate}`;
    logger.debug("uid=" +uid +" | calling: " +apiUrl);

    let retry = 0;
    let resp;
    while (retry < 2) {
      retry++;
      resp = await fetch(
          apiUrl,
          {
            method: 'GET',
            headers: {
              'Authorization': 'Bearer ' + token
            },
          }
      );

      if (resp.status == 401) {
        //Not Authorized
        logger.debug("Token expired");
        //await fetch(refreshTokenUrl, {})
        token = await refreshToken(user.data().dexcom.refresh_token);
        await _firestore.collection('users').doc(authId).set({
          dexcom: {
            token: token,
          }
        }, {merge: true});
      }else {
        break;
      }
    }

    if( resp != null && resp.ok ) {
      let lastRecordTS;
      const results = await resp.json();
      const records = results['records'];


      //create collection record if it doesn't exist.
      const d = await _firestore.collection("cgm_logs").doc(uid);
      if( !d.exists ){
        await _firestore.collection("cgm_logs").doc(uid).set({"uid": uid});
      }

      let batch = _firestore.batch();

      const sensorRef = await _firestore.collection("cgm_logs").doc(uid).collection("sensor_readings");
      for (const record in records) {
        recordCount++;
        const systemTS = Date.parse(records[record]['systemTime'].toString());
        const displayTS = Date.parse(records[record]['displayTime'].toString());

        if(lastRecordTS==null || lastRecordTS < systemTS){
          lastRecordTS = systemTS;
        }


        // @see https://developer.dexcom.com/docs/dexcomv3/operation/getEstimatedGlucoseValuesV3/ for sample json
        batch.set(sensorRef.doc(records[record]['recordId']), {
          "recordId": records[record]['recordId'],
          "systemTime": systemTS,
          "displayTime": displayTS,
          "transmitterId": records[record]['transmitterId'],
          "transmitterTicks": records[record]['transmitterTicks'],
          "value": records[record]['value'],
          "trend": records[record]['trend'],
          "trendRate": records[record]['trendRate'],
          "unit": records[record]['unit'],
          "rateUnit": records[record]['rateUnit'],
          "displayDevice": records[record]['rateUnit'],
          "transmitterGeneration": records[record]['transmitterGeneration'],
        });

        if( !batch.isEmpty && recordCount % 100 == 0 ){
          await batch.commit();
          batch = _firestore.batch();
        }
      }

      if( !batch.isEmpty ){
        await batch.commit();
      }


      if( lastRecordTS != null ) {
        _firestore.collection("cgm_logs").doc(uid).set({
          "system": "dexcom",
          "last_reading_time": lastRecordTS
        });
      }


      logger.debug(`Saved ${recordCount} records | uid=${uid} | startDate=${startDate} - endDate=${endDate}`);
      return {"uid": uid, "records": recordCount};
    }else{
      const err = await resp.text();
      logger.error("Error | " +err);
      throw new HttpsError("unknown", `Error | ${err}`);
    }
  }),

}