# Just run this file by typing this command "./script.sh"
# Make sure that providers.tf and aws-infrastructure.tf files are in the same directory as this script

terraform plan
echo
echo "Building Infrastructure..."
echo
apply=$(terraform apply -auto-approve > terraform_apply.log 2>&1)
if [ $? -ne 0 ]; then
    echo "There is an error building infrastructure !!"
    exit 1
else
    echo "Done Building Infrastructure."
fi



echo "Go check the infrastructure in 'eu-north-1' region."

echo "1 min until the infrastructure get destroyed."

sleep 60

echo "Destroying Infrastructure..."
destroy=$(terraform destroy -auto-approve 2>&1)
if [ $? -ne 0 ]; then
    echo "There is an error destroying infrastructure !!"
    exit 1
else
    echo "Done Destroying Infrastructure."
fi

echo "End Script"
exit 0
