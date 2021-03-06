FROM python:3.8-slim as builder
WORKDIR /app
ENV rds_uri_code ${rds_uri_code}
ENV userinfo_admin_password ${userinfo_admin_password} 
COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt
COPY . .

EXPOSE 5000

CMD ["python3", "managedb.py"]
