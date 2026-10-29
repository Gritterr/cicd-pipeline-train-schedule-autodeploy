# cicd-pipeline-train-schedule-autodeploy

This is a simple train schedule app written using nodejs. It is intended to be used as a sample application for a series of hands-on learning activities.

## Running the app

You need a Java JDK 7 or later to run the build. You can run the build like this:

    ./gradlew build

You can run the app with:

    ./gradlew npm_start

Once it is running, you can access it in a browser at http://localhost:8080

## CI/CD pipeline

Every new commit on `master` runs the [Jenkinsfile](Jenkinsfile):

1. **Build & Test Image**: `docker build`. The [Dockerfile](Dockerfile) installs the dependencies and runs the unit tests, so a failing test stops the pipeline.
2. **Push to Docker Hub**: `saviochristopher/train-schedule:<build number>` and `:latest`.
3. **Deploy to Kubernetes**: applies [k8s/train-schedule.yml](k8s/train-schedule.yml) (Deployment, NodePort Service on 30080, HorizontalPodAutoscaler) with the new image tag and waits for the rolling update. If it fails, the deployment is rolled back.
4. **Smoke Test**: the home page and the `/trains` API must respond.
