#!/bin/bash
set -e

echo -n -e "Finding current cert version for CDN...\t\t"
CONFIGURED_VERSION=$(az cdn custom-domain show --resource-group stuartleekscom --profile-name stuartleekscom --endpoint-name stuartleekscom --name stuartleeks-com -o tsv --query "customHttpsParameters.certificateSourceParameters.secretVersion")
echo "Found $CONFIGURED_VERSION"

echo -n -e "Finding latest cert version in KeyVault...\t"
LATEST_VERSION=$(az keyvault certificate list-versions --vault-name stuartleekscom --name stuartleeks-com --query "[*].{id:id, expires: attributes.expires} | sort_by(@, &expires)[-1].id" -o tsv | sed "s|https://stuartleekscom.vault.azure.net/certificates/stuartleeks-com/||g")
echo "Found $LATEST_VERSION"
echo

if [[ "$CONFIGURED_VERSION" == "$LATEST_VERSION" ]]; then
    echo "Versions match - done"
else
    # echo "Getting current CustomHttpsParameters..."
    # HTTPS_PARAMS=$(az cdn custom-domain show --resource-group stuartleekscom --profile-name stuartleekscom --endpoint-name stuartleekscom --name stuartleeks-com -o json --query "customHttpsParameters")
    # echo -e "Got HTTPS_PARAMS:\n$HTTPS_PARAMS\n"
    
    # UPDATED_HTTPS_PARAMS=$(echo $HTTPS_PARAMS | sed "s/\"secretVersion\"\s*:\s*\"[a-z0-9]*\",/\"secretVersion\": \"$LATEST_VERSION\",/g")
    # echo -e "Updated HTTPS_PARAMS:\n$UPDATED_HTTPS_PARAMS\n"

    UPDATED_HTTPS_PARAMS="{ \"certificateSource\": \"AzureKeyVault\", \"certificateSourceParameters\": { \"@odata.type\": \"#Microsoft.Azure.Cdn.Models.KeyVaultCertificateSourceParameters\", \"subscriptionId\": \"67ce421f-bd68-463d-85ff-e89394ca5ce6\", \"resourceGroupName\": \"stuartleekscom\", \"vaultName\": \"stuartleekscom\", \"secretName\": \"stuartleeks-com\", \"secretVersion\": \"$LATEST_VERSION\", \"updateRule\": \"NoAction\", \"deleteRule\": \"NoAction\" }, \"minimumTLSVersion\": \"TLS12\", \"protocolType\": \"ServerNameIndication\" }"
    echo $UPDATED_HTTPS_PARAMS

    # Since AZ CLI doesn't support setting custom domain properties we're using curl! (https://github.com/Azure/azure-cli/issues/9894)
    echo "Getting Azure auth token..."
    TOKEN=$(az account get-access-token -o tsv --query "accessToken")

    echo "Updating HttpsParams"
    curl https://management.azure.com/subscriptions/67ce421f-bd68-463d-85ff-e89394ca5ce6/resourceGroups/stuartleekscom/providers/Microsoft.Cdn/profiles/stuartleekscom/endpoints/stuartleekscom/customDomains/stuartleeks-com/enableCustomHttps?api-version=2019-04-15 -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" --data "$UPDATED_HTTPS_PARAMS"

    echo
    echo "Use the following command to check progress (watch customHttpsProvisioningState and customHttpsProvisioningSubstate)"
    echo -e "\taz cdn custom-domain show --resource-group stuartleekscom --profile-name stuartleekscom --endpoint-name stuartleekscom --name stuartleeks-com -o jsonc"
fi

