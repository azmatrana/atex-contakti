var cartData = [
  {
    title: "Lorem Ipsum Sit",
    price: "10$",
    quantity: 5,
    images: [
      "image1.png",
      "image2.png",
      "image3.png"
    ]
  },
  {
    title: "Lorem Ipsum Sit 111",
    price: "15$",
    quantity: 2,
    images: [
      "image1.png",
      "image2.png",

    ]
  },
  {
    title: "Lorem Ipsum Sit 222",
    price: "10$",
    quantity: 3,
    images: [
      "image1.png",
      "image2.png",
    ]
  }
]



ContaktiChat.ShoppingCart = function() {
};

function findSum(products){
  let sum = 0 ;
  products.forEach(product => {
    sum += product.price*product.quantity;
  })
  return sum;
}

ContaktiChat.ShoppingCart.prototype.initialise = function() {
  var self = this;
  self.cartData = [];

  if(ContaktiChat.serverUrl.indexOf('http') == -1) {
    ContaktiChat.serverUrl = ContaktiChat.serverProtocol + '://' + ContaktiChat.serverUrl;
  }
  self.itemsTable = document.getElementById('cart_body');
  self.sum = 0;
  self.cartData.forEach( (item, index) =>{
    self.addProduct(item, index);
  });
  self._bindElements();
};

ContaktiChat.ShoppingCart.prototype.addToCart = function(product){
  var self = this;
  if (self.cartData.length === 0){
    ContaktiChat.cartHasProducts = true;
    document.getElementById('cart_show_button').removeAttribute("hidden");
  }
  if (self.cartData.filter(obj => obj.id === product.id).length > 0) {
    return;
  }
  self.sum = 0;
  product.quantity = 1;
  self.cartData.push(product);
  self.itemsTable.innerHTML = '';
  self.cartData.forEach((item, index) =>{
    self.addProduct(item, index)
  });
  self._bindElements()
}

ContaktiChat.ShoppingCart.prototype.removeProduct = function(event){
  var self = this;
  self.sum = 0;
  let btn = event.currentTarget
  let index = btn.id.split("_").pop();
  self.cartData.splice(index, 1);
  self.itemsTable.innerHTML = "";
  document.getElementById("total_amount").getElementsByTagName("strong")[0].innerText = `${self.sum}`;
  self.cartData.forEach((product, index) => self.addProduct( product, index) );
  if (self.cartData.length === 0){
    ContaktiChat.cartHasProducts = true;
    document.getElementById('cart_show_button').setAttribute("hidden", true);
    document.getElementById('contakti_cart_box').style.bottom = '-9999px';
    ContaktiChat.cartHasProducts = false;
  }
  self._bindElements();

}

ContaktiChat.ShoppingCart.listingTemplate = `
  <td class="text-center">1</td>
  <td class="center"><a href="#">Lorem Ipsum Sit blah blah</a></td>
  <td>
     <div  class="center" style="position: relative">
     <span> <i class="fa fa-plus"></i> </span>
     <input type="text" class="form-control" style="width: 50px; margin: 0 auto;" value="5">
     <span > <i class="fa fa-minus" ></i></span> 
</div>

  </td>
  <td class="text-center">€15</td>
  <td class="center">
    <button class="btn btn-danger center remove-item" ><i class="fa fa-times" disabled ></i></button>
  </td>`;


ContaktiChat.ShoppingCart.prototype._bindElements = function() {
  var self = this;
  cartData.forEach((data, index) => {
    var remove_btn = document.getElementById(`remove_${index}`);
    if (remove_btn) {
      remove_btn.addEventListener("click", self.removeProduct.bind(self));
    }
    var increase_btn = document.getElementById(`increase_${index}`);
    if (increase_btn) {
      increase_btn.addEventListener("click", self.increaseCount.bind(self));
    }
    var decrease_btn = document.getElementById(`decrease_${index}`);
    if (decrease_btn) {
      decrease_btn.addEventListener("click", self.decreaseCount.bind(self));
    }
  })

};

ContaktiChat.ShoppingCart.prototype.increaseCount = function(event){
  let self = this;
  let index = event.currentTarget.id.split("_").pop();
  self.cartData[index].quantity += 1;
  let countInput = document.getElementById(`count_${index}`);
  countInput.value = self.cartData[index].quantity;
  self.sum += self.cartData[index].price
  document.getElementById("total_amount").getElementsByTagName("strong")[0].innerText = `${self.cartData[index].currency}${self.sum}`
}
ContaktiChat.ShoppingCart.prototype.decreaseCount = function(){
  let self = this;
  let index = event.currentTarget.id.split("_").pop();
  if (self.cartData[index].quantity == 0){
    return;
  }
  self.cartData[index].quantity -= 1;
  let countInput = document.getElementById(`count_${index}`);
  countInput.value = self.cartData[index].quantity;
  self.sum -= self.cartData[index].price
  document.getElementById("total_amount").getElementsByTagName("strong")[0].innerText = `${self.cartData[index].currency}${self.sum}`;
}

ContaktiChat.ShoppingCart.prototype.addProduct = function(product, index){
  var self = this;
  var listItem = document.createElement("tr");
  if(index%2 == 0){
    listItem.classList.add("grey");
  }
  listItem.innerHTML = ContaktiChat.ShoppingCart.listingTemplate;
  listItem.cells[0].innerText = index+1;
  listItem.cells[1].getElementsByTagName("a")[0].innerText = product.title;
  // listItem.cells[2].innerHTML = `<input type="text" class="form-control" id="count_${index}" style="width: 50px; margin: 0 auto;" value="${product.quantity}">`;
  let countCellInnerHTML = `<div  class="center" style="position: relative">`;
  countCellInnerHTML += `<span id="decrease_${index}"> <i class="fa fa-minus"></i> </span>`;
  countCellInnerHTML += `<input type="text" id="count_${index}" class="form-control" style="width: 50px; margin: 0 auto;" value="${product.quantity}">`;
  countCellInnerHTML += `<span id="increase_${index}"> <i class="fa fa-plus" ></i></span></div>`;
  listItem.cells[2].innerHTML = countCellInnerHTML;
  listItem.cells[3].innerText = ` ${product.price}`;
  var removeButton = listItem.cells[4].getElementsByClassName("remove-item")[0];
  removeButton.setAttribute('id', `remove_${index}`);

  self.itemsTable.append(listItem);
  self.sum += product.price
  document.getElementById("total_amount").getElementsByTagName("strong")[0].innerText = `${product.currency}${self.sum}`

}



var cartData = [
  {
    title: "Lorem Ipsum Sit",
    price: 10,
    quantity: 5,
    images: [
      "image1.png",
      "image2.png",
      "image3.png"
    ]
  },
  {
    title: "Lorem Ipsum Sit 111",
    price: 15,
    quantity: 2,
    images: [
      "image1.png",
      "image2.png",

    ]
  },
  {
    title: "Lorem Ipsum Sit 222",
    price: 10,
    quantity: 3,
    images: [
      "image1.png",
      "image2.png",
    ]
  },
  {
    title: "Lorem Ipsum",
    price: 11,
    quantity: 5,
    images: [
      "image1.png",
      "image2.png",
    ]
  },
  {
    title: "Lorem 222",
    price: 12,
    quantity: 4,
    images: [
      "image1.png",
      "image2.png",
    ]
  }
]




