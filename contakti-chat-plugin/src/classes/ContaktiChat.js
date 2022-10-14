import Api from "./Api";

class ContaktiChat {
    constructor(options = {}) {
        // this.serverProtocol = process.env.PROTOCOL
        if (document.location.origin.includes(":300"))
        {
            this.origin = 'http://localhost:3000'
        }
        else{
            this.origin = document.location.origin
        }

        this.serverUrl = this.origin + '/api/v1'
        this.locale = 'en';
        this.serviceChannel = null;
        this.chat_settings = {};
        this.url_obj = {
            serverUrl: this.serverUrl,
            serverProtocol: this.serverProtocol
        };
        this.api = new Api(this.url_obj);
    }
    setServiceChannel(channel){
        this.serviceChannel = channel;
    }

    async setSettings() {
        let res = await this.api.get(`chat/${this.serviceChannel}/get_chat_settings`);
        this.chat_settings = res.settings;
        this.chat_settings.chat_inquiry_fields = res.chat_inquiry_fields;
        this.chat_settings.chat_initial_buttons = res.chat_initial_buttons;
        this.chatBotEnabled = this.chat_settings.enable_chatbot;
        this.chatWithHuman = !(this.chat_settings.enable_chatbot);
        this.initialMsg = this.chat_settings.initial_msg;
        this.color = this.chat_settings.color;
        this.text_color = this.chat_settings.text_color;
        this.agents_online = res.agents_online;
        this.is_ad_finland = res.is_ad_finland_company
        this.shipment_methods = res.shipment_methods
        this.currency = res.currency || '€'
        this.orderTermsAndConditions = res.order_terms_and_conditions

        this.checkout_methods = []
        if (this.chat_settings.checkout_paytrail) this.checkout_methods.push("checkout_paytrail")
        if (this.chat_settings.checkout_ticket) this.checkout_methods.push("checkout_ticket")

    }

    async setTranslations() {
        this.translations = await this.api.get(`chat/get_translations`);
    }
}

export default ContaktiChat
