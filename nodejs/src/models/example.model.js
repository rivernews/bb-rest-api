let mongoose = require("mongoose");

// db credentials
let host = ''
let databaseName = ''
let user = ''
let password = 'isbn1955'

let connectionString = `mongodb+srv://shaungc:${password}@iriver-mongodb-cluster-umhkt.mongodb.net/test?retryWrites=true`

mongoose.connect(connectionString);

let exampleSchema = new mongoose.Schema({
    
})