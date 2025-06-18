from flask import Flask, render_template, request, redirect, url_for
import subprocess
import threading
from godaddypy import Client, Account

app = Flask(__name__)

# Set your GoDaddy API credentials
PUBLIC_KEY = 'epMMW3puyy9i_4rBhVSUKsh1YPBJ1CfwGTe'
SECRET_KEY = 'DbhBqmwrbPPSsgjCvJKNfK'

# Create an Account and Client object
my_acct = Account(api_key=PUBLIC_KEY, api_secret=SECRET_KEY)
client = Client(my_acct)

def create_instance_thread(instance_name, admin_password, pricing_plan):
    try:
        # Specify the details of the new DNS record
        domain_name = 'business4x.com'

        # Check if the DNS record already exists
        existing_records = client.get_records(domain_name, record_type='A', name=instance_name)
        if existing_records:
            return f"Error: DNS record for {instance_name}.{domain_name} already exists."

        new_record_data = {
            'data': '119.155.141.125',  # Use the actual IP address or retrieve it dynamically
            'name': instance_name,      # Use the instance_name as the subdomain
            'ttl': 3600,
            'type': 'A',
        }

        # Add the new DNS record
        client.add_record(domain_name, new_record_data)

        print(f"DNS record added successfully for {domain_name} and subdomain {instance_name}")

        # Determine the script name based on the pricing plan
        if pricing_plan == 'startup':
            script_name = 'scripts/startup.sh'
        elif pricing_plan == 'small':
            script_name = 'scripts/small.sh'
        elif pricing_plan == 'medium':
            script_name = 'scripts/medium.sh'
        elif pricing_plan == 'large':
            script_name = 'scripts/large.sh'
        else:
            return "Error: Invalid pricing plan"

        # Run the instance creation script
        command = f'bash {script_name} "{instance_name}" "{admin_password}"'
        result = subprocess.run(command, shell=True, capture_output=True, text=True)

        print(result.stdout)
        print(result.stderr)
    except Exception as e:
        print(f"Error: {e}")

@app.route('/')
def pricing_plan():
    return render_template('pricingplan.html')

@app.route('/create_instance', methods=['POST'])
def create_instance():
    instance_name = request.form['instance_name']
    admin_password = request.form['admin_password']
    pricing_plan = request.form['pricing_plan']

    try:
        # Check if the DNS record already exists
        existing_records = client.get_records('business4x.com', record_type='A', name=instance_name)
        if existing_records:
            return render_template('error.html', error_message=f"Error: DNS record for {instance_name}.business4x.com already exists.")

        # Start the instance creation in a separate thread
        create_thread = threading.Thread(target=create_instance_thread, args=(instance_name, admin_password, pricing_plan))
        create_thread.start()

        return render_template('loading.html', instance_name=instance_name)
    except Exception as e:
        print(f"Error: {e}")
        return render_template('error.html', error_message=str(e))

@app.route('/go_back', methods=['GET'])
def go_back():
    return redirect(url_for('pricing_plan'))

if __name__ == '__main__':
    # Change the host argument to the desired IP address
    app.run(host='localhost', port=5000, debug=True)
