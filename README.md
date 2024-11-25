TASKS:

------- 1 -----------

1A)
HTTP Endpoint for candidate 55 | Form: [ {"prompt":"prompt specifications"} ] | JSON Body
(https://jlpwdljdi9.execute-api.eu-west-1.amazonaws.com/Prod/generate/)

1B)
Link to github actions workflow successfull SAM-Deploy to AWS | This is latest/last run flow for this specific workflow. 
I couldn't find my first successfull one that had everything working perfectly but there was no specification for which one so I linked this:
(https://github.com/schumi0/dev-ops-img-gen/actions/runs/12017182743)

------- 2 -----------

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

-------- 3 ---------

docker run -e AWS_ACCESS_KEY_ID=<> -e AWS_SECRET_ACCESS_KEY=<> -e SQS_QUEUE_URL=https://sqs.eu-west-1.amazonaws.com/244530008913/titanv1-img-gen-queue carls_image "prompt"

Beskrivelse av taggestrategi:

Naming strategy is based on GitHubs -rev | Every single image is named after its commits' commit hash except for the latest which gets named "latest". 

I chose this tagging strategy because of the commit hash and how it would be easier to find specific versions of the program based on git commits instead of having to check dates, run the program or whatever else you would otherwise need
to do to check you're running the version you want. 

Docker container image:
(schumi0/cara011_java_sqs_client:latest)

-------- 4 ---------

Address for config of alarm can be changed in config file for tf (terraform.tfvars)
Cloudwatch Alarm:
(cara011_last_message_que_alarm)

------- 5 ----------

