import React, { Component } from 'react';
import ContaktiChat from '../../classes/ContaktiChat';
import Dropdown from './Dropdown';
import ChatBox from '../chat_box/ChatBox';
import CallBackBox from '../others/CallBackBox';
import ChatUtils from '../../classes/ChatUtils';
import ReactResizeDetector from 'react-resize-detector/build/withPolyfill';
import Cart from '../shopping_cart/Cart';
import ProductInfoModal from '../shopping_cart/ProductInfoModal';

class ChatPlugin extends Component {
  constructor(props) {
    super(props);
    this.state = {
      style: {},
      contaktiChat: {},
      translations: {},
      loading: true,
      showDropDown: false,
      showNoAgentScreen: false,
      showPlugin: false,
      showMinimize: false,
      chatStarted: false,
      chatInitialized: false,
      showCartIcon: false,
      showCart: false,
      cartEmpty: true,
      showProductModal: false,
      selectedProduct: {},
      disableChatboxContent: false
    }
  }
  handleProductModalClose = () => {
    this.setState({ showProductModal: false })
  };
  handleProductModalShow = (p) => {
    this.setState({ showProductModal: true, selectedProduct: p });
  }

  async componentDidMount() {
    let contakti_chat = new ContaktiChat();
    let chatUtils = ChatUtils
    let urlParams = chatUtils.getUrlParams(window.location.href)
    let serviceChannelId = urlParams.id;
    contakti_chat.setServiceChannel(serviceChannelId);
    await contakti_chat.setSettings();
    await contakti_chat.setTranslations();

    this.setState({
      contaktiChat: contakti_chat,
      loading: false,
      style: {
        color: contakti_chat.text_color,
        backgroundColor: contakti_chat.color
      }
    });
  }

  toggleDropDown = (flag) => {
    this.setState({ showDropDown: flag });
  }
  setChatStarted = () => {
    if (!this.state.chatStarted) {
      this.setState({ chatStarted: true });
    }
  }
  showNoAgentOnlineScreen = (e) => {
    this.setState({ showNoAgentScreen: true });
    if (e) e.preventDefault();
  }
  showChatPlugin = async () => {
    if (!this.state.chatInitialized) {
      this.setState({ chatInitialized: true });
    }
    if (!this.state.showPlugin) {
      let cont_chat = this.state.contaktiChat
      await cont_chat.setSettings();
      this.setState({ showPlugin: true, showMinimize: true, contaktiChat: cont_chat });

      if (this.state.chatStarted) {
        this.setState({ showDropDown: true });
      }
      if (!this.state.cartEmpty) {
        this.setState({ showCartIcon: true });
      }

    }

  }
  hideChatPlugin = (e) => {
    e.stopPropagation();
    if (this.state.showPlugin) {
      this.setState({ showPlugin: false, showMinimize: false, showDropDown: false, showCart: false, showCartIcon: false });
    }
  }
  destroyChat = () => {
    this.setState({ chatInitialized: false, showPlugin: false, showMinimize: false, showDropDown: false, showCartIcon: false, cartEmpty: true });
  }
  onResize = (width, height) => {
    // if (width < 350){
    //   // width = 350;
    // }
    // if ( height < 535)
    // {
    //   // height = 535;
    // }
    window.parent.postMessage({ type: 'set_dimensions', width, height }, "*");
  }
  toggleCart = () => {
    this.setState({ showCart: !this.state.showCart });
  }
  addToCart = (product) => {
    this.setState({ showCartIcon: true, showCart: true, cartEmpty: false }, () => this.cart.addProduct(product));
  }
  hideCartIcon = () => {
    this.setState({ showCartIcon: false, showCart: false, cartEmpty: true });
  }

  setPluginDisabledState = (disabled = false) => {
    this.setState({ disableChatboxContent: disabled });
  }

  createCartTicket = async ( customerId, products, checkout_method, shipment_method, priceWithoutTaxes="", taxes="", sum ) => {
    this.setPluginDisabledState( true );
    const taskId = await this.chatBox.createTicket(
			true,
			products,
			priceWithoutTaxes,
			taxes,
			shipment_method.price,
			sum,
			this.state.contaktiChat.translations.user_dashboard.shopping_cart
				.order_products
		);
    await this.chatBox.createOrder(
			taskId,
			customerId,
			products,
			checkout_method,
			shipment_method,
			sum
		);
    this.chatBox.setOrderCreated();
    this.cart.handleCustomerFormModalClose();
    this.setState({ showCart: false, showCartIcon: false });
    this.setPluginDisabledState( false );
  }


  render() {
    const { contaktiChat, loading } = this.state;
    let parent_width_class = '';

    if (window.parent) {
      if (window.outerWidth <= 600) {
        parent_width_class += ' max-600-width '
      }
    }

    if (loading) {
      return null;
    }

    return (
      <div id="contakti-chat-main" className={parent_width_class}>
        <ReactResizeDetector handleWidth handleHeight onResize={this.onResize} >
          <div id="contakti-msg-box"
            className={`
                 chat-plugin-parent
                 ${this.state.showMinimize === true ? "open" : ""}
              `}
          >
            <ProductInfoModal
              buttonColor={contaktiChat.color}
              product={this.state.selectedProduct}
              handleShow={this.handleProductModalShow}
              handleClose={this.handleProductModalClose}
              show={this.state.showProductModal}
              origin={contaktiChat.origin}
              currency={ contaktiChat.currency }
              translations={contaktiChat.translations.user_dashboard.shopping_cart}
            />
            <div className={"cart-parent" + (this.state.disableChatboxContent ? ' disabled-content' : '')} style={{ display: this.state.showCart ? "block" : "none" }}>
              {(!this.state.cartEmpty) && contaktiChat.chat_settings.enable_cart ? (
                <Cart ref={instance => { this.cart = instance; }}
                    handleShow={this.handleProductModalShow}
                    contaktiChat={contaktiChat}
                    onCartEmpty={this.hideCartIcon}
                    toggleCart={this.toggleCart}
                    handleOrder={this.createCartTicket}
                    setPluginDisabledState={ this.setPluginDisabledState }/>
              ) : ""}
            </div>

            <div className={"chat-parent flex-column d-flex" + (this.state.disableChatboxContent ? ' disabled-content' : '')}>
              <div id="contakti-msg-head" onClick={this.showChatPlugin} className="msg_head" style={this.state.style}>
                <div>
                  <div id="contakti-logo-container">
                    <img alt="logo" src={`${contaktiChat.origin}/${contaktiChat.chat_settings.file.url}`} />
                  </div>
                </div>

                <span id="contakti-user-name" style={{ color: contaktiChat.text_color }}>{contaktiChat.chat_settings.chat_title}</span>

                <span id="cart_show_button" onClick={this.toggleCart} style={{ display: this.state.showCartIcon ? "block" : "none", margin: '5px 5px 0 0', color: contaktiChat.text_color }}>
                  <i className="fa fa-shopping-cart mt-1"></i>
                </span>
                <span>
                  {this.state.showDropDown ? (<Dropdown styleObj={this.state.style} translations={contaktiChat.translations} showDropdown={this.state.showDropDown} quit={() => { this.chatBox.quitChat(); this.destroyChat() }} sendChatHistory={() => this.chatBox.showSendChatHistory()} downloadChatHistory={() => { this.chatBox.downloadChat(); }} startChat={() => this.showChatPlugin()} />) : ""}
                </span>

                <div id="contakti-msg-minimize" >
                  {this.state.showMinimize ? (
                    <span className="fa-stack" onClick={this.hideChatPlugin} style={{ color: contaktiChat.text_color }}><i className="fa fa-stack-2x fa-angle-down" style={{ top: '3px', left: '0px' }}></i></span>
                  ) : ""}
                </div>
              </div>
              {this.state.chatInitialized ? (
                <div  style={{ display: this.state.showPlugin ? "block" : "none" }}>
                  {this.state.showNoAgentScreen ? (<CallBackBox contaktiChat={contaktiChat} showNoAgentOnlineScreen={this.showNoAgentOnlineScreen} ></CallBackBox>) : (
                    <ChatBox ref={instance => { this.chatBox = instance; }}
                      contaktiChat={contaktiChat}
                      handleProductShow={this.handleProductModalShow}
                      toggleDropDown={this.toggleDropDown}
                      showNoAgentOnlineScreen={this.showNoAgentOnlineScreen}
                      quit={() => { this.destroyChat() }}
                      setChatStarted={this.setChatStarted}
                      startChat={() => this.showChatPlugin()}
                      addToCart={(product) => { this.addToCart(product) }}
                      setPluginDisabledState={this.setPluginDisabledState}
                    ></ChatBox>)}
                </div>
              ) : ""}
            </div>
          </div>
        </ReactResizeDetector>
      </div>
    );
  }
}

export default ChatPlugin;
