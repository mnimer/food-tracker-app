const {logger} = require("firebase-functions");
const {onRequest} = require("firebase-functions/v2/https");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");


const {VertexAI} = require('@google-cloud/vertexai');

//params
const { defineString, defineSecret } = require('firebase-functions/params');
//const projectId = defineString("projectId");
const storageBucket = defineSecret("storageBucket");
const geminiApiKey = defineSecret("geminiApiKey");


//initialize genai
const vertex_ai = new VertexAI({project: 'food-tracker-414517', location: 'us-central1'});
// Instantiate the models
const generativeModel = vertex_ai.preview.getGenerativeModel({
  model: 'gemini-1.0-pro-vision-001',
  generation_config: {
    "max_output_tokens": 2048,"temperature": 0,"top_p": 1,"top_k": 32
  },
  safety_settings: [
    {"category": "HARM_CATEGORY_HATE_SPEECH","threshold": "BLOCK_MEDIUM_AND_ABOVE"},
    {"category": "HARM_CATEGORY_DANGEROUS_CONTENT","threshold": "BLOCK_MEDIUM_AND_ABOVE"},
    {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT","threshold": "BLOCK_MEDIUM_AND_ABOVE"},
    {"category": "HARM_CATEGORY_HARASSMENT","threshold": "BLOCK_MEDIUM_AND_ABOVE"}],
});



var _firestore;
var _storage;
module.exports = {
  init: function(firestore_, storage_){
    _firestore = firestore_;
    _storage = storage_;
  },
  foodTrigger: onRequest((request, response) => {
    logger.info("Hello food trigger!", {structuredData: true});
    response.send("Hello food trigger");
  }),
  onFoodActivityCreateHandler: onDocumentCreated("food_logs/{userId}/activity/{documentId}", async (context) => {
    logger.info("food Image OnCreate Handler | user=" + context.params.userId + " | document=" + context.params.documentId, context.params);
    //logger.info("food Image OnCreate snapshot", context.data.data());

    // Retrieve the current and previous value
    const data = context.data.data();
    //logger.info(JSON.stringify(data));

    //Only run the AI if the user uploaded an image.
    if( data.type != "image") return;


    context.data.ref.update({
      "status": "processing",
    });

    //Get path params
    const userId = context.params.userId;
    const documentId = context.params.documentId;
    //const user = context.data.after.data();


    //Get BASE64 of uploaded Image 
    const imageRef = _storage.bucket().file(data.storagePath);
    logger.info(imageRef.mime_type);
    //logger.info(imageRef);

  
    const file = await imageRef.download();
    const base64String = Buffer.from(file[0]).toString('base64');
    //logger.info(base64String);

    

    //Build AI model request

    //todo get coach from user;
    //todo pull from coaches collection
    const coachBackStory = "You are a trained nutritionist focused on helping people reverse or prevent metabolic syndrome and insulin resistance. Your goal is to help people avoid sugars and food that spikes insulin, like carbs. What do you think of this dish?";
    const goodImageInstructions = "If this is an image of food, \n" + 
      "-Create a short title to describe this dish \n  " +
      "-Create a description of this dish \n  " +
      "-Create a list of the ingredients and their serving size \n " +
      "-Create a list of nutients (Calories, Protein, Carbs, Sugar, and Fat) for the ingredients of this dish \n";
    const badImageInstructions = "If it is not food or you can not figure out what it is, return \"unknown\" as the title in the json";

    const req = {
      contents: [
        {role: 'user', 
        parts: [
          {text: coachBackStory +"\n\n" +goodImageInstructions +"\n\n" +badImageInstructions },
          {inline_data: {mime_type: 'image/jpeg', data:base64String}}, 
          {text: "return results as a json object formatted like this:\n\n {\"title\": \"title\", \"description\":\"description\", \"ingredients\": [ {\"name\": \"ingredient\", \"quantity\": \"1oz\"}, {\"name\": \"ingredient\", \"quantity\": \"2oz\"}], \"nutrients\": [ {\"name\", \"nutrient\", \"quantity\": \"1g\"}, {\"name\", \"nutrient\", \"quantity\": \"2g\"} ]}"}]}],
        };
      
    const aiResp = await generativeModel.generateContent(req);    
    var fullResponse = aiResp.response;

    try{
      var response = fullResponse.candidates[0].content.parts[0].text;
      logger.info('response: ' + response);

      var title = response;
      var description = "";
      var ingredients = [];
      var nutrients = [];
      var responseStr = response.trim();
      //check for markup around result
      if( responseStr.startsWith("```") && responseStr.endsWith("```") ){
        var start = responseStr.indexOf("{");
        var end = responseStr.lastIndexOf("}");
        responseStr = responseStr.substring(start, end+1);
      }

      if( responseStr.startsWith("{") && responseStr.endsWith("}")){
        var respomseParse = JSON.parse(responseStr);
        title = respomseParse.title;
        description = respomseParse.description;
        ingredients = respomseParse.ingredients;
        nutrients = respomseParse.nutrients;
        logger.info("title=" +title +" | description=" +description);
      }else{
        logger.info("title=" +title );
      }


      //Save results
      context.data.ref.update({
        "name": title,
        "description": description,
        "ingredients": ingredients,
        "nutrients": nutrients,
        "ai_response": JSON.stringify(fullResponse),
        "ai_datetime": new Date().getTime(),
        "status": "complete",
      });
      //"ingredients": respomseParse.ingredients,
      //"nutrients": respomseParse.nutrients
    } catch( err ){
      logger.info('Error: ' +err);
      logger.info('API Response: ' +JSON.stringify(fullResponse));

      context.data.ref.update({
        "name": 'unknown',
        "status": "complete",
      });
    }

  })
}