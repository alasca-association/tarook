# Coding Guide

## Disruption

**Definition:** A *disruption* is defined as a loss of state or data or loss of
availability.

**Definition:** *Disruptive* code is code which may under certain circumstances
cause a disruption.

Ansible code MUST be written so that it is non-disruptive by default. It is only
allowed to execute disruptive actions if and only if the `_allow_disruption`
variable evaluates to true.

### Examples

(Non-exhaustive) examples of disruptive actions:

- Restarting docker (for example via a docker upgrade)
- Draining a worker or master node
- Killing a pod
- Rebooting a worker or master node with an OSD on it

Examples of non-disruptive actions:

- Rebooting a gateway node if at least one other gateway node is up
- Updating a (non-customer) Deployment via Kubernetes

## Ansible Styleguide

### New-style module syntax

**Correct**

```yaml
- name: Upgrade all packages
  dnf:
    name:
    - '*'
    state: latest
```

**Incorrect**

```yaml
- name: Upgrade all packages
  dnf: name=* state=latest
```

**Rationale:** The first version is easier to scan. It also supports the use of Jinja2 templates without having to worry about quotation and spaces.


### Command module usage

**Correct**

```yaml
- name: Get node info
  command:
  args:
    argv:
    - kubectl
    - describe
    - node
    - "{{ inventory_hostname }}"
```

*Also correct*

```yaml
- name: Get node info
  command:
  args:
    argv: ["kubectl", "describe", "node", "{{ inventory_hostname }}"
```

**Not correct**

```yaml
- name: Get node info
  command: "kubectl describe node {{ inventory_hostname }}"
```

**Rationale:** Spaces and possibly quotes in the hostname would lead to issues.

### Shell module usage


**Correct**

```yaml
- name: Load shared public key
  shell: "wg pubkey > {{ wg_local_pub_path | quote }} < {{ wg_local_priv_path | quote }}"
```

**Not correct**

```yaml
- name: Load shared public key
  shell: "cat {{ wg_local_priv_path }} | wg pubkey > {{ wg_local_pub_path | quote }}"
```

**Partially better**

```yaml
- name: Load shared public key
  shell: "set -o pipefail && cat {{ wg_local_priv_path }} | wg pubkey > {{ wg_local_pub_path | quote }}"
```

**Rationale:**
* Using pipes in the shell module can lead to silent failures without `set -o pipefail`
* Variables should be properly escaped. A ';' or a '&&' in, e.g., the path can lead to funny things. Especially critial if the content of the variable can be influenced from the outside.
* [The use of cat here is redundant](http://porkmail.org/era/unix/award.html#cat)

### Use to\_json in templates when writing YAML or JSON

**Correct:**

```
{
   "do_create": {{ some_variable | to_json }}
}
```

**Incorrect:**

```
{
   "do_create": {{ some_variable }}
}
```

**Also incorrect:**

```
{
   "do_create": "{{ some_variable }}"
}
```

**Rationale:** If `some_variable` contains data which can be interpreted as different data type in YAML (such as `no` or `true` or `00:01`) or quotes which would break the JSON string, unexpected effects or syntax errors can occur. `to_json` will properly encode the data.

## Terraform Styleguide

### Use jsonencode in templates when writing YAML

**Correct:**

```
subnet_id: ${jsonencode(some_subnet_id)}
```

**Incorrect:**

```
subnet_id: ${some_subnet_id}
```

**Also incorrect:**

```
subnet_id: "${some_subnet_id}"
```

**Rationale:** If `some_subnet_id` contains data which can be interpreted as different data type in YAML (such as `no` or `true` or `00:01`), unexpected effects can occur. `jsonencode()` will wrap the `some_subnet_id` in quotes and also take care of any necessary escaping.
