# Mockoon

If you set up Mockoon using `docker-compose.yml` (see the main docker compose strategy for Kafka, Mockoon, and PostgreSQL), you will always have a `mockoon-env.json` file in a mockoon directory. You can set up mock endpoints in this file and when running under the docker profile, you can point to these endpoints to get mock responses.

## Creating the initial `mockoon-env.json` file.

- Go get the contents of a existing mockoon file that you have in another solution as an example of the expected format. 
- Name it `mockoon-env-example.json` and put it in the mockoon folder in your solution that your `docker-compose.yml` file points to.
- Create an empty `mockoon-env.json` file in which to write the contents of the new endpoint mock definitions to in the same directory.
- Download or copy the swagger definitions from the existing endpoints that you wish to mock and add them to their respective YAML or JSON files in the same directory. Now the AI can use these files to populate the endpoint information in `mockoon-env.json`. In the prompt below these manifest as `ecm-swagger.yml` as an example.
- With these files in context ask the AI (Copilot) to import the required endpoints into the `mockoon-env.json`. Here is an example prompt:
```
Using `mockoon-env-example` as an example of the version and format of how to create the required mockoon file for docker-compose to use, I would like to import the `GET /api/documents/{documentId}/content` endpoint information from the `ecm-swagger` swagger documentation and the `POST /api/v1/drafting/generate-document` endpoint information in order to use the dockerized Mockoon service to mock calls to these endpoints from this service into the `mockoon-env.json` file.

Please also give me cURL commands that I can use to test these endpoints with test data?
```
- The response should also give you two cURL commands which you should use immediately with `docker compose up` to spin up Mockoon and test that these endpoints work.
- When everything is working, you should be able to use Mockoon UI application to point to this file and from here on in you'll be able to edit and manage from Mockoon UI.

> When you make changes, remember to commit them to keep things in sync.

- Use prompts like this to manage the addition of new endpoints using the swagger documentation.

```
We need to add the POST /api/v2/documents/encoded endpoint information from ecm-swagger.yaml to the mockoon-env.yaml file and generate a cURL command that we can use to test it.
```
or...
```
Let's remove this endpoint from the mockoon-env.json file: `GET "http://localhost:3001/api/documents/b198dda0-b3cd-4755-82ab-5e66fa8f7709/content"`
```


#### Ensure compatibility with Docker and Mockoon UI

- Format: Mockoon v29 compatible JSON format
- Port: 3001 (matches your docker-compose configuration)
- CORS: Enabled
- Headers: Configured for both ECM and Drafting Service request/response headers
- Sample Data: Includes realistic UUIDs and base64-encoded content for testing

## Picking up Changes

You can pick up changes to `mockoon-env.json` without running `docker compose down`, but you do need to restart the Mockoon container so it reloads the updated file.

**Recommended approach:**
```sh
docker compose restart mockoon
```
This will:
- Stop and start only the mockoon service/container
- Reload the latest `mockoon-env.json` from your volume mount
- Leave other services (like your database) running

**Summary:**  
Just run `docker compose restart mockoon` after editing `mockoon-env.json` to apply changes. No need for a full `down`/`up` cycle.

## Supporting more than one downstream services (multiple ports)

You can run multiple Mockoon environments locally by creating separate environment JSON files (e.g., `mockoon-env-1.json`, `mockoon-env-2.json`) and starting a Mockoon CLI container for each one, each on a different port.

To do this in your docker-compose.yml, add a new service for each environment, specifying a unique container name, port, and volume mapping for each environment file. For example:

```yaml
mockoon-env1:
  image: mockoon/cli:latest
  container_name: mockoon-env1
  volumes:
    - ./mockoon/mockoon-env-1.json:/data/mockoon-env.json:ro
  command: >
    --data /data/mockoon-env.json
    --port 3002
  ports:
    - "3002:3002"

mockoon-env2:
  image: mockoon/cli:latest
  container_name: mockoon-env2
  volumes:
    - ./mockoon/mockoon-env-2.json:/data/mockoon-env.json:ro
  command: >
    --data /data/mockoon-env.json
    --port 3003
  ports:
    - "3003:3003"
```

Each service will run its own Mockoon environment on a separate port. Just create the corresponding environment files in your mockoon directory.

Most of the time you don't need to do this as your mocked endpoints across the server will probably be different and can be accessed over a single port.

## References

- [Introduction to Mockoon - May 2020](https://www.youtube.com/watch?v=7BXGhKA1sjk&list=PLdLxWqlJRmn4ep4WKejwcFpM39ZEJIfmT&index=2) from the [Mockoon community tutorials](https://www.youtube.com/playlist?list=PLdLxWqlJRmn4ep4WKejwcFpM39ZEJIfmT)

# Older Stuff

```bash
docker compose up -d
curl http://localhost:3001/hello
# → {"message":"Hello from Mockoon!"}
```

#### Handle multiple files

Using the following approach to create multiple files to better organise your mockoon endpoints:
```
.
├─ docker-compose.yml
└─ mockoon/
   ├─ customers.json      # port 3001
   ├─ inventory.json      # port 3002
   └─ payments.json       # port 3003

```

If each file has a different port, one can expose those ports. Also, simply using `/data` as the data folder will load all the `.json` files in that folder.

```yaml
services:
  mockoon:
    image: mockoon/cli:latest
    container_name: mockoon
    volumes:
      # mount the whole folder read-only
      - ./mockoon:/data:ro
    command:
      # load *all* JSON files found in /data
      - "--data" "/data"
      # optional: watch for changes and auto-reload
      - "--watch"
      # optional: make sure old files are auto-upgraded
      - "--repair"
    ports:
      # expose each environment’s own port
      - "3001:3001"
      - "3002:3002"
      - "3003:3003"

```
Now, your Spring-Boot app (or Postman, etc.) calls:
- http://localhost:3001/... for Customers
- http://localhost:3002/... for Inventory
- http://localhost:3003/... for Payments

#### Seperate container approach (same or overlapping ports)

**Advantages:** Each environment can run on the same port number inside its own container (if you ever need that). You can turn individual mocks on/off with docker compose up mockoon-inventory.

**Downside:** a bit more YAML to maintain.

```yaml
services:
  mockoon-customers:
    image: mockoon/cli:latest
    volumes:
      - ./mockoon/customers.json:/data/env.json:ro
    command: ["--data", "/data/env.json", "--port", "8080"]
    ports:
      - "8080:8080"

  mockoon-inventory:
    image: mockoon/cli:latest
    volumes:
      - ./mockoon/inventory.json:/data/env.json:ro
    command: ["--data", "/data/env.json", "--port", "8081"]
    ports:
      - "8081:8081"

```

#### Handy CLI flags

| Flag                 | Purpose                                                                       |
| -------------------- | ----------------------------------------------------------------------------- |
| `--watch`            | Auto-reload when you edit the JSON on disk. Great for live tweaking.          |
| `--repair`           | Quietly migrate any “too old” env file on startup (avoids the yes/no prompt). |
| `--log-transaction`  | Prints every incoming request/response to the container logs.                 |
| `--data base folder` | If you point to a folder, **all `*.json` files** inside are loaded.           |

#### Organising inside a single env file (fallback)

If you must stick to one file per service but still want order, the Mockoon GUI lets you create folders to group routes, give them colours, collapse/expand, etc. Those folders carry over to the CLI automatically.

#### Auto-repair

If your JSON is in Mockoon ≤ v1.x format (it still has the legacy "type": "environment" / "version": "3.4.0" duo and no lastMigration field), add the `--repair` to the command. This should attempt to make a fix without the yes/no prompt that will break your `docker compose` command. However, a re-export is recommended.

```yaml
command:
  - "--data" "/data/mockoon-env.json"
  - "--port" "3001"
  - "--repair"          # migrate without the yes/no prompt
```



# **How to Echo Request Data in Mockoon**

Mockoon supports **Handlebars templating**, which lets you read values from the incoming request and echo them back in the mock response.

---

## **1. Echo values from the request body**

### **Helper**

```
{{body 'fieldName'}}
```

### **Example**

Request:

```json
{ "id": "12345" }
```

Mockoon response body:

```json
{ "echoedId": "{{body 'id'}}" }
```

---

## **2. Echo values from request headers**

### **Helper**

```
{{header 'header-name'}}
```

(Header names are case-insensitive, best written in lowercase.)

### **Example**

```json
{
  "auth": "{{header 'authorization'}}",
  "correlation": "{{header 'x-correlation-id'}}"
}
```

---

## **3. Echo values from query parameters**

### **Helper**

```
{{queryParam 'paramName'}}
```

### **Example**

For request:

```
GET /items?type=premium
```

Mockoon response:

```json
{ "itemType": "{{queryParam 'type'}}" }
```

---

## **4. Echo entire objects (for debugging)**

* All headers:

  ```
  {{headers}}
  ```

* Full request body:

  ```
  {{body}}
  ```

* All query params:

  ```
  {{queryParams}}
  ```

---

## **5. Nested fields**

```
{{body 'data.id'}}
{{queryParam 'filters.status'}}
```

---

## **6. Conditional logic (optional)**

```handlebars
{{#if (header 'x-user-id')}}
  "userId": "{{header 'x-user-id'}}"
{{else}}
  "userId": "not provided"
{{/if}}
```

---

# **Summary**

Use Mockoon’s built-in request helpers to dynamically echo incoming data:

* **Body:** `{{body 'field'}}`
* **Headers:** `{{header 'name'}}`
* **Query params:** `{{queryParam 'name'}}`
* **Full request objects:** `{{body}}`, `{{headers}}`, `{{queryParams}}`

These helpers let you return GUIDs, tokens, IDs, or any other incoming values directly in your mock responses.
