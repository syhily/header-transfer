## A simple plugin for kong.

Remove specific request's header and transfer it to your request body.

### Usage

1. `luarocks install header-transfer`
2. Edit your `kong.yml` configuration file, add a item below your `custom_plugins`. You may need unquote it first.

```yaml
custom_plugins:
 - header-transfer
```
3. Add the header-transfer plugin to your api.

`curl -X POST http://nyan.ameho.me:8001/apis/<your api id>/plugins --data "name=header-transfer" --data "config.head_to_body=a_header:some_value, another_header:some_value"`

4. The header your specificed in your configuration would be transfer to your request body accounding to your request method.
HTTP GET would be your queryString, HTTP POST would be x-form-url-encoded.
