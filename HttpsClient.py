import requests

# define the endpoint URL
url = 'https://10.1.1.1:3000/api/data'

# define the data to be sent in JSON format
data = {
    "name": "Python Client",
    "age": 32,
    "email": "Guido.van.Rossum@google.com",
    "address": {
        "street": "PO Box 118-263",
        "city": "Amsterdam",
        "state": "Netherlands",
        "zip": "1991"
    }
}

# send the POST request with the data as JSON payload
#response = requests.post(url, json=data, verify=False)
response = requests.post(url, json=data, verify='d:/ssl2/ca-cert.pem')

# check the response status code and message
if response.status_code == 200:
    print('Data sent successfully')
    print(response.text)
else:
    print('Error:', response.text)