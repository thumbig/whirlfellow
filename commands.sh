###############################################################
###############################################################
# Run backend locally

cd backend
npm install
npm start

###############################################################
###############################################################

npm install -g @angular/cli


###############################################################
###############################################################
# Frontend

# Create angular app 
cd ..
ng new frontend --routing=false --style=css
cd frontend
npm install
# Then edit src/app/app.component.ts 

ng build --configuration production


###############################################################
###############################################################

aws configure
aws sts get-caller-identity

###############################################################
###############################################################
# Deploy

cd terraform
terraform init # -upgrade
terraform plan
terraform apply # -auto-approve
#Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
#Outputs: public_ip = "98.81.159.205"

## checks
echo $(terraform output -raw public_ip)
ping 98.81.159.20
terraform state list

curl http://$(terraform output -raw public_ip):3000/api/hello

terraform destroy

###############################################################
###############################################################

ssh -i ~/.ssh/id_rsa ec2-user@$(terraform output -raw public_ip)
sudo tail -n 50 /var/log/whirlfellow-init.log
node -v
npm -v
sudo cat /var/log/cloud-init-output.log | tail -50
ps aux | grep node
cat /home/ec2-user/whirlfellow/backend/app.log



###############################################################
###############################################################
