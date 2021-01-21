import ballerina/http;
import ballerina/log;
import ballerina/io;
import ballerina/docker;

@docker:Config {}
@docker:CopyFiles {
    files: [
        { sourceFile: "./conf/Config.toml", target: "/home/ballerina/conf/Config.toml", isBallerinaConf: true },
        { sourceFile: "./conf/data.txt", target: "/home/ballerina/data/data.txt" }
    ]
}

@docker:Expose {}
listener http:Listener helloWorldEP = new(9090);

configurable string users = "Not found";
configurable string groups = "Not found";

service http:Service /helloWorld on helloWorldEP {
    resource function get config(http:Caller caller, http:Request request) returns @tainted error? {
        http:Response response = new;
        string payload = "Configuration: " + users + " " + groups;
        response.setTextPayload(payload + "\n");
        var responseResult = caller->respond(response);
        if (responseResult is error) {
            log:printError("error responding back to client.", err = responseResult);
        }
    }

    resource function get data(http:Caller caller, http:Request request) returns @tainted error? {
        http:Response response = new;
        string payload = readFile("./data/data.txt");
        response.setTextPayload("{'data': '" + <@untainted> payload + "'}\n");
        var responseResult = caller->respond(response);
        if (responseResult is error) {
            log:printError("error responding back to client.", err = responseResult);
        }
    }
}

function readFile(string filePath) returns  string {
    io:ReadableByteChannel bchannel = checkpanic io:openReadableFile(filePath);
    io:ReadableCharacterChannel cChannel = new io:ReadableCharacterChannel(bchannel, "UTF-8");

    var readOutput = cChannel.read(50);
    if (readOutput is string) {
        return <@untainted> readOutput;
    } else {
        return "Error: Unable to read file";
    }
}
