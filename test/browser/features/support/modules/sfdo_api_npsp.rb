module Sfdo_api_npsp
  # NPSP will automatically create certain fields on certain objects based on required input values for those records.
  # There is no way to know in advance from the API which these are, so we find them empirically and note them here
  # before calling the create() method in SfdoAPI
  @fields_acceptibly_nil = { 'Contact': ['Name'],
                             'Opportunity': ['ForecastCategory'] }
  def create_account_via_api(account_name)
    record_type_id = select_api "select Id from RecordType where DeveloperName = 'HH_Account'"
    @account_id = create 'Account', Name: account_name, RecordTypeId: record_type_id.first.Id
  end

  def create_organization_account(account_name)
    # record_type_id = select_api "select Id from RecordType where DeveloperName = 'HH_Account'"
    record_type_id = select_api "select Id from RecordType where DeveloperName = 'Organization'"
    @account_id = create 'Account', Name: account_name, RecordTypeId: record_type_id.first.Id
  end

  def create_contact_via_api(client_name, street = '', city = '', state = '', country = '', zip = '')
    @contact_id = create 'Contact', LastName: client_name,
                                    MailingStreet: street,
                                    MailingCity: city,
                                    MailingState: state,
                                    MailingCountry: country,
                                    MailingPostalCode: zip
    @contact_name = client_name
    account_object = select_api "select AccountId from Contact where Id = '#{@contact_id}'"
    my_account_object = account_object.first
    @account_id_for_contact = my_account_object.AccountId
    @array_of_contacts << @contact_id
  end

  def create_two_contacts_on_account_via_api(client_name1, client_name2)
    @contact_id = create 'Contact', LastName: client_name1
    @contact_name = client_name1
    @array_of_contact_names << client_name1
    account_object = select_api "select AccountId from Contact where Id = '#{@contact_id}'"
    my_account_object = account_object.first
    @account_id_for_contact = my_account_object.AccountId
    @array_of_contacts << @contact_id
    @contact_id = create 'Contact', LastName: client_name2, AccountId: @account_id_for_contact
    @contact_name = client_name2
    @array_of_contact_names << client_name2
    @array_of_contacts << @contact_id
  end

  def create_two_contacts_on_different_accounts(client_name1, client_name2)
    @contact_id_first = create 'Contact', LastName: client_name1
    @contact_name_first = client_name1
    @array_of_contact_names << client_name1
    account_object = select_api "select AccountId from Contact where Id = '#{@contact_id_first}'"
    my_account_object = account_object.first
    @account_id_for_first_contact = my_account_object.AccountId
    @array_of_contacts << @contact_id_first

    @contact_id_second = create 'Contact', LastName: client_name2
    @contact_name_second = client_name2
    @array_of_contact_names << client_name2
    account_object = select_api "select AccountId from Contact where Id = '#{@contact_id_second}'"
    my_account_object = account_object.first
    @account_id_for_second_contact = my_account_object.AccountId
    @array_of_contacts << @contact_id_first
  end

  def create_contacts_with_household_object_via_api(hh_obj, contact_name)
    @hh_obj_id = create 'Household', Name: hh_obj
    #@contact_id = create 'Contact', { LastName: contact_name, Household: @hh_obj_id }
    @contact_id = create 'Contact', { LastName: contact_name, Household: @hh_obj_id }
    @array_of_contacts << @contact_id
    #@contact_id = create 'Contact', LastName: contact_name, MailingCity: 'hhmailingcity', npo02__Household__c: @hh_obj_id
    @contact_id = create 'Contact', LastName: contact_name, MailingCity: 'hhmailingcity', Household: @hh_obj_id
    @array_of_contacts << @contact_id
  end

  def populate_soft_credit(role)
    api_client do
      hs_id = select_api 'select Id from Households_Settings'
      hs = hs_id.first
      hs.npo02__Soft_Credit_Roles__c = role

      @sc_id = update_api(hs)
      end
  end

  def create_gau_via_api(gau_name)
    @gau_id = create 'General_Accounting_Unit', Name: gau_name
  end

  def create_lead_via_api(last_name, company)
    @lead_id = create 'Lead', LastName: last_name, Company: company
  end

  def create_opportunity_via_api(client_name, stage_name, close_date, amount, account_id, matching_gift_status = '', matching_gift_account = '')
    @opportunity_id = create 'Opportunity',
                             Name: client_name,
                             StageName: stage_name,
                             CloseDate: close_date,
                             Amount: amount.to_i,
                             AccountId: @account_id_for_contact,
                             Matching_Gift_Status: matching_gift_status,
                             Matching_Gift_Account: matching_gift_account
    @array_of_opp_ids << @opportunity_id

  end

  def create_relationship_via_api(contact, related_contact)
    #@relationshiop_id = create 'Relationship', npe4__Contact__c: contact, npe4__RelatedContact__c: related_contact
    @relationshiop_id = create 'Relationship', Contact: contact, RelatedContact: related_contact
  end

  def delete_account_via_api
   delete_one_account(@account_id)
  end

  def delete_contacts_via_api
    api_client do
      cons = select_api 'select Id from Contact'
      delete_all_contact(cons)
    end
  end

  def delete_engagement_plan_templates
    api_client do
      epts = select_api 'select Id from Engagement_Plan_Template'
      delete_all_Engagement_Plan_Template(epts)
    end
  end

  def delete_gaus_via_api
    api_client do
      gaus = select_api 'select Id from General_Accounting_Unit'
      delete_all_General_Accounting_Unit(gaus)
    end
  end

  def delete_household_accounts
    api_client do
      hh_accs = select_api "select Id from Account where Type = 'Household'"
      hh_accs.each do |hh_acc|
        @api_client.destroy(hh_acc.sobject_type, hh_acc.Id)
      end
    end
  end

  def delete_household_objects
    api_client do
      hh_objs = select_api 'select Id from Household'
      delete_all_Household(hh_objs)
    end
  end

  def delete_leads
    api_client do
      leads = select_api 'select Id from Lead'
      leads.each do |lead_id|
        @api_client.destroy(lead_id.sobject_type, lead_id.Id)
      end
    end
  end

  def delete_payments
    api_client do
      payments = select_api 'select Id from OppPayment'
      delete_all_OppPayment(payments)
    end
  end

  def delete_non_household_accounts
    api_client do
      nh_accs = select_api 'select Id from Account where Type = null'
      delete_all_account(nh_accs)
    end
  end

  def delete_opportunities
    api_client do
      rd_opps = select_api 'select Id from Opportunity'
      delete_all_opportunity(rd_opps)
    end
  end

  def delete_recurring_donations
    api_client do
      rds = select_api 'select Id from Recurring_Donation'
      delete_all_Recurring_Donation(rds)
    end
  end

  def update_account_model(to_value)
    api_client do
      acc_id = select_api 'select Id from Contacts_And_Orgs_Settings'
      acc = acc_id.first
      #THIS NEEDS A CHANGE TO SFDO-API TO SEND THESE VALUES THROUGH true_field()
      acc.npe01__Account_Processor__c = to_value

      update_api(acc)
    end
  end

  def reset_these_settings(these_settings_obj)
    @api_client.update_api(these_settings_obj)
  end

  def set_url_and_object_namespace_to_npsp
    # Not sure why this is required here, but $instance_url isn't being set elsewhere all times this is called
    if not $instance_url and ENV['SF_INSTANCE_URL']
      $instance_url = ENV['SF_INSTANCE_URL']
    end
    case ENV['TARGET_ORG']
      when 'unmanaged'
        if $instance_url.include? "my.salesforce.com"
          $target_org_url = $instance_url.gsub(/https:\/\/([\w-]+)\.(\w+)\.my.salesforce.com/, 'https://\1--c.\2.visual.force.com')
        else
          interim_url = $instance_url.sub('https://', 'https://c.')
          $target_org_url = interim_url.sub('my.salesforce.com', 'visual.force.com')
          $target_org_url = interim_url.sub('salesforce.com', 'visual.force.com')
        end
        $object_namespace = ''
      when 'gs0'
        $target_org_url = $instance_url.sub('gs0.salesforce.com', 'npsp.gus.visual.force.com')
        $object_namespace = 'npsp__'
      else
        #THE MOST COMMON CASE, MANAGED CODE IN A DEVELOPMENT ORG
        # MyDomain example: https://ability-momentum-7120-dev-ed.cs70.my.salesforce.com
        #     becomes: https://ability-momentum-7120-dev-ed--npsp.cs70.visual.force.com
        # Pod example: https://na35.salesforce.com
        #     becomes: https://npsp.na35.salesforce.com
        if $instance_url.include? "my.salesforce.com"
          $target_org_url = $instance_url.gsub(/https:\/\/([\w-]+)\.(\w+)\.my.salesforce.com/, 'https://\1--npsp.\2.visual.force.com')
        else
          interim_url = $instance_url.sub('https://', 'https://npsp.')
          $target_org_url = interim_url.sub('my.salesforce.com', 'visual.force.com')
          $target_org_url = interim_url.sub('salesforce.com', 'visual.force.com')
        end
        $object_namespace = 'npsp__'
    end
  end

  def login_with_oauth
    require 'faraday'

    if ENV['SF_ACCESS_TOKEN'] and ENV['SF_INSTANCE_URL']
      $instance_url = ENV['SF_INSTANCE_URL']
      @access_token = ENV['SF_ACCESS_TOKEN']
    else
      conn = Faraday.new(url: ENV['SF_SERVERURL']) do |faraday|
        faraday.request :url_encoded # form-encode POST params
        # faraday.response :logger                  # log requests to STDOUT
        faraday.adapter Faraday.default_adapter # make requests with Net::HTTP
      end

      response = conn.post '/services/oauth2/token',
                           grant_type: 'refresh_token',
                           client_id: ENV['SF_CLIENT_KEY'],
                           client_secret: ENV['SF_CLIENT_SECRET'],
                           refresh_token: ENV['SF_REFRESH_TOKEN']

      response_body = JSON.parse(response.body)
      @access_token = response_body['access_token']
      $instance_url = response_body['instance_url']
    end
    
    @browser.goto($instance_url + '/secur/frontdoor.jsp?sid=' + @access_token)
  end
end
