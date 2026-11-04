import logging
from flask import Flask

app = Flask(__name__)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
)


@app.get("/")
def home():
    app.logger.info("Homepage requested")
    return {"message": "Hello from the DevOps lab"}, 200


@app.get("/health")
def health():
    app.logger.info("Health endpoint requested")
    return {"status": "ok"}, 200


@app.errorhandler(404)
def not_found(error):
    app.logger.warning("Unknown path requested")
    return {"error": "not_found"}, 404
