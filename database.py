from flask import Flask, request, jsonify
import mysql.connector

app = Flask(__name__)

db_config = {
    "host": "localhost",  
    "user": "root",    
    "password": "your password", 
    "database": "your database name" 
}

def get_db_connection():
    return mysql.connector.connect(**db_config)

@app.route('/save_user', methods=['POST'])
def save_user():
    try:
        data = request.json
        name = data.get('name')
        email = data.get('email')
        phone = data.get('phone')

        if not name or not email or not phone:
            return jsonify({"error": "Name, email, and phone are required"}), 400

        connection = get_db_connection()
        cursor = connection.cursor()
        query = "INSERT INTO user_details (name, email, phone) VALUES (%s, %s, %s)"
        cursor.execute(query, (name, email, phone))
        connection.commit()

        cursor.close()
        connection.close()

        return jsonify({"message": "User data saved successfully", "id": cursor.lastrowid}), 201

    except Exception as e:
        print(e)
        return jsonify({"error": str(e)}), 500

@app.route('/save_weather', methods=['POST'])
def save_weather():
    try:
        data = request.json
        cityname = data.get('cityname')
        temp = data.get('temp')

        if not cityname or temp is None:
            return jsonify({"error": "City name and temperature are required"}), 400

        connection = get_db_connection()
        cursor = connection.cursor()
        query = "INSERT INTO weather_details (cityname, temp) VALUES (%s, %s)"
        cursor.execute(query, (cityname, temp))
        connection.commit()

        cursor.close()
        connection.close()

        return jsonify({"message": "Weather data saved successfully", "id": cursor.lastrowid}), 201

    except Exception as e:
        print(e)
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
