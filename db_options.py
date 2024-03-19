import json

with open('og_input.json') as f:
    data = json.load(f)
    inner_data = data[0]   
    for element in inner_data:
        del element['OptionDescription']
        del element['Persistent']
        del element['Permanent']
    
        option_settings = element.get('OptionSettings')
        element['OptionSettings'] = [obj for obj in option_settings if obj['Name'] != 'MODE']

        vpc_security_group_memberships = element.get('VpcSecurityGroupMemberships')
        new_vpc_security_group_memberships = []
        for vpc_element in vpc_security_group_memberships:
            new_vpc_security_group_memberships.append(vpc_element.get('VpcSecurityGroupId'))
        element['VpcSecurityGroupMemberships'] = new_vpc_security_group_memberships

    with open('og_output.json', 'w') as f:
        json.dump(inner_data, f, indent=4)