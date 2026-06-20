# Creating Your Helm Chart

The `helm` cli tool offers a create command that will layout a set of starter templates and helper functions, you should always start with this no matter how simple the chart will be. [More details](helm.sh/docs/helm/helm_create/)

```bash
helm create 'my-sweet-new-chart'
```

## Helper Functions (Named Templates)

### The `_helpers.tpl` File

This file made by `helm create` contains helper functions for sticking to consistent naming and labeling of resources. I recommend you do not touch this file, as at some point you may want to upgrade and teasing out your stuff from what comes baked in would be difficult.

### Making Your Own Helpers

Every file under `templates` folder, prefixed with `_`, and having the `tpl` extension, will be processed by the `helm` cli tool when rendering templates, leverage this to keep your helper functions organized and maintainable. [More details](https://helm.sh/docs/chart_template_guide/named_templates/)

[Tips & Tricks/Lessons Learned coming soon]

# Helm-Docs

The [helm-docs](https://github.com/norwoodj/helm-docs) project is a tool that automatically generates Markdown documentation for Helm charts from metadata, values, and annotations so documentation can stay consistent and up to date as charts evolve.

It has a default template that will generate a README.md file at the root of the chart, but also supports customizable Go templates. To override the default `README.md` template just create your template named `README.md.gotmpl`. [More details](https://github.com/norwoodj/helm-docs#user-content-markdown-rendering)

## How To Include `values.yaml` Nodes In Docs

Start by adding comment lines directly above the nodes you want documented in `values.yaml`. helm-docs reads these comments and uses them as the description column in the generated Values table. [More details](https://github.com/norwoodj/helm-docs#user-content-helm-docs)

Example:

```yaml
service:
	# -- Kubernetes Service type used to expose the app
	type: ClusterIP

	# -- Service port used by clients
	port: 80
```

### The Default Column

I recommend limiting documentation to scalar nodes as that makes your docs more concise, and the automatic defaults will turn map/list nodes into JSON strings that can make the rendered markdown very ugly. If you do want to annotate map/list nodes you can override the text to keep the output clean

```yaml
# -- Configures resource requests and limits for the containers
# @default -- cpu: 10m-500m memory: 256Mi-1Gi
resources:
  requests:
    cpu: 10m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 1Gi
```

Another behavior I find unappealing with the default template is when you have empty values or sets. An unset scalar node will show `nil`, an empty list `[]`, and an empty map `{}`. I work around this with a magic string in my custom templates that forces the `Default` column to an empty string which conveys the same info with less uneccessary noise

Template:
```md
| Key | Type | Default | Description |
|-----|------|---------|-------------|
| {{ .Key }} | {{ .Type }} | {{ if eq .AutoDefault "~empty" }}{{ "" }}{{ else if .Default }}{{ .Default }}{{ else }}{{ .AutoDefault }}{{ end }} | {{ if .Description }}{{ .Description }}{{ else }}{{ .AutoDescription }}{{ end }} |
```

Values:
```yaml
appSettings:
  ConnectionStrings:
    # -- Sets the Postgres connection string
    # @default -- ~empty
    PostgresContext:
```

## Rendering The Docs

You a few options for [installation and usage](https://github.com/norwoodj/helm-docs#user-content-installation), but my preferred method is to run it in a Docker container

```bash
docker run --rm --volume './chart-root-dir:/helm-docs' --name 'helm-docs' --user "$(id -u):$(id -g)" jnorwood/helm-docs:latest --sort-values-order file
```

## What This Chart's README.md Would Look Like <small><small><small>(I've interlaced useful info in context)</small></small></small>

---

# basic-helm-chart

Value pulled from the `description` field in Chart.yaml.

### Generaal Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| replicaCount | int | `1` | Sets how many replicas of the application to run |
| image.repository | string | `"someRepo/someDotNetApp"` | Sets the container image repository to pull from. |
| image.pullPolicy | string | `"IfNotPresent"` | Sets the pull policy for images. [More details](https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy) |
| image.tag | string | `"latest"` | Overrides the image tag whose default is the chart appVersion. |
| imagePullSecrets | list |  | This is for the secrets for pulling an image from a private repository. [More details](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) |
| nameOverride | string |  | Overrides the chart name |
| fullnameOverride | string |  | Overrides the chart full name |
| serviceAccount | object | Creates and automounts a service account with the same name as the release name. | This section builds out the service account. [More details](https://kubernetes.io/docs/concepts/security/service-accounts/) |
| podAnnotations | object |  | Annotations to be added to all pods |
| podLabels | object |  | Labels to be added to all pods |
| podSecurityContext | object |  | Sets the security context for all pods. [More details](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/) |
| securityContext | object |  | Sets the security context for all containers. [More details](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/) |

### Application Settings

An introduction to the settings and details of some of the nuances that are tough to convey in a simple table with snippet explanations. Generally I'm able to just say something like `If there's no default value then it is required unless otherwise noted`. For when that hasn't been the best option I have been able to make custom properties for helm-docs that I will show in another sample chart for more advanced techniques.

| Key (appSettings.*) | Type | Default | Description |
|---------------------|------|---------|-------------|
| ConnectionStrings.PostgresContext | string |  | Sets the Postgres connection string |
| httpsPort | int | `5443` | Sets the port the application listens on |
| someMap | object | `{"listInMap":["item1","item2"],"mapInMap":{},"someNestedValue":""}` | This and example of how a map/list would look if you leave the automatic default generation |

---

Autogenerated from chart metadata and values using [helm-docs](https://github.com/norwoodj/helm-docs).
