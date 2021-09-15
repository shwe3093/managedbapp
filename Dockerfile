FROM python:3.8-slim as builder
WORKDIR /app
COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt
COPY . .

EXPOSE 5000

CMD ["python3", "managedb.py"]
