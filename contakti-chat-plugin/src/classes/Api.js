const Api = function (options= {}) {
    
    // this.serverUrl = process.env.HOST_NAME
    // this.serverProtocol = process.env.PROTOCOL
    // this.origin = options.host || 'http://localhost:3000'

    if (document.location.origin.includes(":300"))
    {
        this.origin = 'http://localhost:3000'
    }
    else{
        this.origin = document.location.origin
    }
    
    this.serverUrl = this.origin + '/api/v1'
    this.baseUrl = this.serverUrl;
}

Api.prototype.origin = "ASdas"

Api.prototype.get = async function (route = '') {
    const res = await fetch(`${this.baseUrl}/${route}`)
    const data = await res.json()
    if (!data) {
        return null
    }
    else {
        return data
    }
}
Api.prototype.post = async function (route = '', data = {}) {
    const response = await fetch(`${this.baseUrl}/${route}`, {
        method: 'POST',
        cache: 'no-cache',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(data) 
    });
    return await response.json();
}

Api.prototype.postFile = async function (route = '', file_data = {}) {
    const response = await fetch(`${this.baseUrl}/${route}`, {
        method: 'POST',
        cache: 'no-cache',
        body: file_data 
    });
    return await response.json();
}
export default Api


