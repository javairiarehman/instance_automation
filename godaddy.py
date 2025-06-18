from godaddypy import Client, Account

# Set your GoDaddy API credentials
PUBLIC_KEY = 'epMMW3puyy9i_4rBhVSUKsh1YPBJ1CfwGTe'
SECRET_KEY = 'DbhBqmwrbPPSsgjCvJKNfK'
# Create an Account and Client object
my_acct = Account(api_key=PUBLIC_KEY, api_secret=SECRET_KEY)
client = Client(my_acct)

try:
    # Specify the details of the new DNS record
    domain_name = 'erisp.co'
    new_record_data = {
        'data': '119.155.141.125',
        'name': 'khannn',
        'ttl': 3600,
        'type': 'A',
    }

    # Add the new DNS record
    client.add_record(domain_name, new_record_data)

    print(f"DNS record added successfully for {domain_name}")
except Exception as e:
    print(f"Error: {e}")
