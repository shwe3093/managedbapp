FROM python:3.8-slim as builder
COPY . /src
RUN pip3 install -r requirements.txt

EXPOSE 5000

CMD ["python3", "app.py"]
