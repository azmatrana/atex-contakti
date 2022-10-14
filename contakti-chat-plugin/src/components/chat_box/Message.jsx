import React, { Component } from 'react';
import moment from 'moment';
import ChatUtils from '../../classes/ChatUtils';
import Text from '../modules/utils/Text';
import MessageImagesModal from './MessageImagesModal';
class Message extends Component {
  constructor(props) {
    super(props);
    this.state = {
      username: this.props.userName,
      fromTime: this.props.envelope.from === this.username ? 'time_b' : 'time_a',
      fromColor: this.props.from === this.username ? 'from_b' : 'from_a',
      imageIndex: null,
      showModal: false,
      modalImages: []
    }
  }
  handleMessageImageShow = (index, images) => {
    this.setState({ imageIndex: index, showModal: true, modalImages: images});
  }
  handleMessageImageClose = () => {
    this.setState({ showModal: false  });
  }

  render() {
    var { contaktiChat } = this.props;

    return (
      <div className={this.props.bgClass} >
        <MessageImagesModal
         showModal={this.state.showModal}
         activeIndex={this.state.imageIndex}
         images={this.state.modalImages}
         handleClose={this.handleMessageImageClose}
         origin={contaktiChat.origin}/>
        {this.props.envelope.type === 'file' ? (
          <a download target="_blank" rel="noreferrer" href={ChatUtils.replaceAllNewLines(this.props.envelope.message)}>{`${this.props.envelope.from} ${contaktiChat.translations.user_dashboard.upload_chat}`}</a>

        ) : (
          <Text text={ChatUtils.replaceAllNewLines(ChatUtils.replaceURLs(this.props.envelope.message))} />
        )}
        { this.props.envelope.images ? (<div style={{gridTemplateColumns: "auto auto auto auto"}} className="d-grid mt-1">
          { this.props.envelope.images.map((image, index) => {
            return(<div className="me-1 mb-1">
              <img src={`${contaktiChat.origin}${image.file.url}`} onClick={() => { this.handleMessageImageShow(index, this.props.envelope.images)}} style={{borderColor: contaktiChat.color}} className="img-thumbnail"></img>
            </div>)
          })}

        </div>) : ""
        }
        {
          this.props.envelope.files ? (this.props.envelope.files.map((file) => {
            return (
              <div>
                <a download target="_blank" rel="noreferrer" href={file.url}>{file.name}</a>
              </div>)

          })) : ""
        }
        {this.props.envelope.products ? (
          <div id="chat-answer-products-wrapper" className="mt-1">
            {this.props.envelope.products.map(product => {
              return (<div className="answer_product" key={`product-item-${product.id}`}>
                <div className="child1"><strong>{product.title}</strong> </div>
                <div className="child2">
                  <a href="#" onClick={() => this.props.addToCart(product)} className="add-to-cart-btn" data-product-id={product.id} style={{ color: contaktiChat.text_color, backgroundColor: contaktiChat.color }}>
                    <i className="fa fa-shopping-cart"></i>
                  </a>
                </div>
                <span onClick={() => {this.props.handleProductShow(product)}}> <i className="fa fa-info-circle" aria-hidden="true"></i> </span>
              </div>)
            })
            }
          </div>
        ) : ""}

        {this.props.envelope.action_buttons ? (
          <div>
               {this.props.envelope.action_buttons.map((btn, i) => {
              return (
                <div key={`action-buttons-${i}`}>
                  <br />
                  {btn.hyper_link && btn.hyper_link.length > 0 ? <a href={((!/^https?:\/\//i.test(btn.hyper_link))?'http://': "") + btn.hyper_link} className="action-button" target="_blank" style={{ backgroundColor: contaktiChat.color, color: contaktiChat.text_color }}><Text text={btn.text} /></a> :
                    <button className="action-button" style={{ backgroundColor: contaktiChat.color, color: contaktiChat.text_color }} onClick={this.props.sendCustomActionMessage}><Text text={btn?.text} /> </button>
                  }
                  <br />
                </div>
              )

            })
            }
          </div>

        ) : ""}
        {
          this.props.envelope.type !== 'quit' && this.props.envelope.type !== 'initial' ? (
            <div>
              <br />
              <div className={`msg_time${this.state.fromTime}`}> {moment(this.props.envelope.timestamp ? this.props.envelope.timestamp : "").local().format('D.M.YYYY HH.mm')}</div>
              <div className={`msg_from${this.state.fromColor}`}>{this.props.envelope.from} </div>
              {this.props.envelope.from === this.props.userName ? (
                <div>
                  {this.props.userInfo.map((info, i) => {
                    return (<div key={`user-info-${i}`} className={`msg_from${this.state.fromColor}`}>{info} </div>)
                  })}
                </div>
              ) : ""}
            </div>
          ) : ""}
      </div>);
  }
}

export default Message;
