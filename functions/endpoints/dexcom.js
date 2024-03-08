const {logger} = require("firebase-functions");
const {onRequest} = require("firebase-functions/v2/https");

//params
const { defineString, defineSecret } = require('firebase-functions/params');
//const projectId = defineString("projectId");
//const storageBucket = defineSecret("storageBucket");
const dexcomClientId = defineSecret("dexcomClientId");
const dexcomSecret = defineSecret("dexcomSecret");


var _firestore;
module.exports = {
  init: function(firestore_){
    _firestore = firestore_;
  },
  
  getDexcomToken: onRequest( async (request, response) => {
    var code = request.query.code;
    var uid = request.query.state;
    logger.info("Dexcom Token | code=" +code +" | uid=" +uid, {structuredData: true});

    try{
      var url = "https://api.dexcom.com/v2/oauth2/token";
      url = "https://sandbox-api.dexcom.com/v2/oauth2/token";

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

        await _firestore.collection('users').doc(uid).set({
          dexcom: {
            token: data.access_token,
            refresh_token: data.refresh_token,
            token_type: data.token_type,
            token_expires: data.expires_in,
            token_expiresTs: expiresTS
          }
        }, {merge: true});

        console.log("User=" +uid +" updated");

        response.send(data);
      }else{
        response.status(500).send("Error | " +resp.text());
      }

    }catch(e){
      console.log(e);
      response.status(500).send("Error | " +e);
    }
  }),


  getDexcomReadings: onRequest((request, response) => {
    logger.info("Hello food trigger!", {structuredData: true});
    response.send("Hello food trigger");
  }),
}