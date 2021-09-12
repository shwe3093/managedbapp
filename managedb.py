from flask import Flask, request, jsonify, render_template
from flask_sqlalchemy import SQLAlchemy

app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = "mysqlurl"
db = SQLAlchemy(app)

class User(db.Model):
    user_id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String)
    email = db.Column(db.String)

@app.route("/<name>",methods=['GET'])
def find_email(name):
    try:
        result = User.query.filter_by(username=name).first()
        return result.email
        #return "Hello World"
    except:
        return "User not found"

@app.route("/all",methods=["GET"])
def all_users():
    try:
        result = User.query.all()
        list_users = []
        for user in result:
            user_dict = {}
            user_dict["username"] = user.username
            user_dict["email"] = user.email
            list_users.append(user_dict)
        #print(list_users)
        #return jsonify(list_users)
        return render_template('users.html', list_users=list_users)
    except:
        return "Unable to query db"

@app.route("/")
def index():
    return render_template('index.html')

app.run(host='0.0.0.0', port=5000)
