TASKS:

----------- 1 -----------

1A)
HTTP Endpoint for candidate 55 | Form: [ {"prompt":"prompt specifications"} ] | JSON Body
(https://jlpwdljdi9.execute-api.eu-west-1.amazonaws.com/Prod/generate/)

1B)
Link to github actions workflow successfull SAM-Deploy to AWS | This is latest/last run flow for this specific workflow. 
I couldn't find my first successfull one that had everything working perfectly but there was no specification for which one so I linked this:
(https://github.com/schumi0/dev-ops-img-gen/actions/runs/12017182743)


----------- 2 -----------

2 A+B) 
On this task I succeeded multiple times with terraform apply, but in the newer versions of my setup I didn't want to delete old roles and I got "errors" in the terraform apply code. The code ran, however, and my CLI got a green light so...
Anyways, the first one is a successfull one with no issues, and the second one is one of the latest/last runs of that workflow, so you can see the difference. Everything should still work, however.

Successfull terraform apply on branch "main":
(https://github.com/schumi0/dev-ops-img-gen/actions/runs/11933061356/job/33259332631)
(Almost) Successfull terraform apply on branch "main":
(https://github.com/schumi0/dev-ops-img-gen/actions/runs/12017182734/job/33498953250)


Successfull terraform plan on branch "stagingv2":
(https://github.com/schumi0/dev-ops-img-gen/actions/runs/11933232268/job/33259865265)


SQS Que Link:
(https://sqs.eu-west-1.amazonaws.com/244530008913/titanv1-img-gen-queue)


----------- 3 -----------

docker run -e AWS_ACCESS_KEY_ID=<> -e AWS_SECRET_ACCESS_KEY=<> -e SQS_QUEUE_URL=https://sqs.eu-west-1.amazonaws.com/244530008913/titanv1-img-gen-queue carls_image "prompt"

Beskrivelse av taggestrategi:

Naming strategy is based on GitHubs -rev | Every single image is named after its commits' commit hash except for the latest which gets named "latest". 

I chose this tagging strategy because of the commit hash and how it would be easier to find specific versions of the program based on git commits instead of having to check dates, run the program or whatever else you would otherwise need
to do to check you're running the version you want. 

Docker container image:
(schumi0/cara011_java_sqs_client:latest)


----------- 4 -----------

4)
Address for config of alarm can be changed in config file for tf (terraform.tfvars)
Cloudwatch Alarm:
(cara011_last_message_que_alarm)


----------- 5 -----------

5)
A serverless architecture using AWS Lambda and tools like Amazon SQS works quite differently from a microservices approach, especially when it comes to automation, monitoring, scalability, and team responsibilities. Serverless makes managing infrastructure much simpler, but it  complicates Continuous Integration/Continuous Delivery (CI/CD) pipelines. Each small, independent function usually needs its own pipeline, which lets you roll out updates quickly but adds complexity as systems grow. Microservices, on the other hand, group more functionality into fewer services. This simplifies pipeline management but requires more effort to handle environments and infrastructure. 
  Monitoring and observability are trickier in a Function-as-a-Service (FaaS) setup. Serverless workflows often have many small, independent steps that can fail unexpectedly, and because these functions only run briefly, you don’t get much feedback beyond the  response from the endpoint you’re calling. Without persistent processes or "safety rails," debugging and tracing issues in serverless systems can feel like solving a puzzle with missing pieces. Microservices, with their longer-running components, provide more stability and make it easier to trace errors, like AWS Lambda functions, where you get a response based on the servers' response and no specified error log to help you out.  Unless you put it in yourself, that is. I'd argue that fixing errors localy will most likely always be easier than searching through an entire tech stack to find a specific case issue. 
  Scalability and cost control vary, too. Serverless scales automatically to match demand, and you only pay for what you use, which is perfect for workloads that spike or fluctuate. But if you have constant high usage, serverless can get expensive. Microservices also scale but require manual setup and run constantly, so you’re dealing with fixed costs. For steady workloads, this can be cheaper, depending on the specifics. In short, serverless gives you flexibility, while microservices offer more predictable costs.
  Using  Serverless functions and architecture you pawn a lot of the maintanence responsibility onto the architecture providers. Because of this, though, developers now have to be ready to respond at any given time if something goes wrong. Imagine if you were on vacation and you had to go on your work laptop because an alarm rang when a commit failed to deploy, or a change lost the company money. Microservices, on the other hand, give the team full control over everything, from infrastructure to performance. That control comes with more responsibility, like making sure things scale properly and keeping costs low. Serverless is (supposedly) easier to manage, but microservices let you have more direct control..
