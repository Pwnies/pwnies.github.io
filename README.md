# Pwnies web page

Static blog made in Jekyll, hosted on https://pwnies.dk via the gcloud project `pwnies-skyen`.

To run locally, use `www-pwnies-skyen/build_and_serve.sh`.

To deploy, you need to:
 * Get the correct rights by talking to Kokjo
 * Download `google-cloud-sdk`

and then run:

```
gcloud auth login
gcloud config set project pwnies-skyen
./build_and_upload.sh
```
