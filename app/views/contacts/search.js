$("#contacts-table-wrapper").html("<%= escape_javascript(render 'contacts/table', contacts: @contacts, public_phonebook: params[:public_phonebook]) %>");
