import React, { Component } from 'react';
import ChatUtils from '../../classes/ChatUtils';

class Product extends Component {
  constructor(props) {
    super(props);
    this.state = {
    }
  }


  onProductRemove = (p) => {
    this.props.onProductRemove(p);
  }

  increaseQuantity = (product) => {
    this.props.increaseQuantity(product)
  }

  decreaseQuantity = (product) => {
    if (product.quantity > 1) {
      product.quantity -= 1;
      this.props.replaceProduct(product)
    }
  }


  render() {
    let { products, currency } = this.props;
    const {translations} = this.props

    return (
      <table className="table table-condensed table-striped ">
        <thead>
          <tr>
            <th className="border-0">{translations.product_title}</th>
            <th className="border-0 text-center">{translations.quantity}</th>
            <th className="border-0 text-center">{translations.price}</th>
            <th className="border-0 text-center">{translations.vat}</th>
            <th className="border-0 text-center">{translations.action}</th>
          </tr>
        </thead>

        <tbody id="cart_body">
          {
            products.map((product, index) => {
              return <tr key={index}>
                <td className="px-1 border-0"><a href="#" onClick={()=> { this.props.handleShow(product) }}>{product?.title}</a></td>
                <td className="px-1 border-0">
                  <div className="center" style={{ position: "relative" }}>
                    <span onClick={() => this.increaseQuantity(product)}> <i className="fa fa-plus"></i> </span>
                    <input type="text" className="form-control" style={{ width: "50px", margin: "0px 5px" }} value={product?.quantity} readOnly />
                    <span onClick={() => this.decreaseQuantity(product)} > <i className="fa fa-minus" ></i></span>
                  </div>
                </td>
                <td className="px-1 border-0 text-center">{ChatUtils.displayPrice(product?.price)}{currency}</td>
                <td className="px-1 border-0 text-center">{product?.vat ? product.vat?.vat_percentage : 0 }%</td>
                <td className="px-1 border-0 center">
                  <button
                    onClick={() => this.onProductRemove(product)}
                    className="btn btn-danger " ><i className="fa fa-times" disabled ></i></button>
                </td>
              </tr>

            })
          }
        </tbody>

      </table>

    );
  }
}
export default Product;