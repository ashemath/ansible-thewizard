# Ansible Roles and "The Wizard"
Ansible's role features are really helpful for creating reusable chunks of
configuration.

I wanted to create a fun context for exploring roles, so I built this
little project that debugs Black Sabbath's "The Wizard".

## Try it out:

### Clone the repository:

`git clone https://github.com/ashemath/ansible-thewizard`

### Install ansible:
You can install ansible in a Python venv with the provided script:

`./setup_ansible`

Activate your the installed venv by running `source bin/activate`
This will add the venv's packages to your PATH variable until you run
`deactivate`. 

Alternatively, you could use system-level ansible. This project
uses only core ansible functionality.

### Run the playbook
`ansible-playbook apply_roles.yml`


## The design
### "The Wizard"
The song has three verses and a chorus that repeats after each verse.
The chorus changes on the 2nd iteration, and stays that way for the
3rd.

We'll be using task, variable, and meta main.yml files. Here's the `tree`
of the folder structure:

```
roles/
├── role_a
│   ├── tasks
│   │   ├── chorus.yml
│   │   └── main.yml
│   └── vars
│       └── main.yml
├── role_b
│   ├── meta
│   │   └── main.yml
│   ├── tasks
│   │   └── main.yml
│   └── vars
│       └── main.yml
└── role_c
    ├── meta
    │   └── main.yml
    ├── tasks
    │   └── main.yml
    └── vars
        └── main.yml
```
### The playbook file
We're going to run all three roles by calling for only the last role in
the dependency chain.

`apply_roles.yml`

```
---
- name: apply roles
  hosts: localhost
  
  roles:
    - role_c
```

### The dependency chain
When we call role_c, it is dependent on role_b, and role_b is dependent on
role_a

```
$ cat roles/role_b/meta/main.yml`
dependencies:
  - role: role_a
```

```
$ cat roles/role_c/meta/main.yml
dependencies:
  - role: role_b
```

### The task files
The task file for role_a does most of the heavy lifting.
It executes debug message tasks that "sing" the lyrics.

I include a idempotency exercise that pulls on the `role_name` special
variable to craft a file in a generated `proof/` folder.

`roles/role_a/tasks/main.yml`

```
- name: What role are we executing?
  debug: 
    msg: "We are running this task for {{ role_name }}"

- name: Print verse specified for this role.
  debug:
    msg: "{{ item.msg }}"
  loop: "{{ verse }}"

- name: include the chorus
  import_tasks:
    file: "{{ playbook_dir }}/roles/role_a/tasks/chorus.yml"

- name: Ensure the proof folder exists
  file:
    path: "{{ playbook_dir }}/proof/"
    state: directory
  run_once: true

- name: idempotency/proof task
  lineinfile:
    path: "{{ playbook_dir }}/proof/{{ role_name }}"
    line: "{{ role_name }} was here"
    create: yes

- name: import role_a's tasks
  import_tasks:
    file: "{{ playbook_dir }}/roles/role_a/tasks/main.yml"
- name: import role_a's tasks
  import_tasks:
    file: "{{ playbook_dir }}/roles/role_a/tasks/main.yml"
```
The task file for role_b just imports the tasks from role_a, and we
do the same thing with role_c:

`roles/role_b/tasks/main.yml`

```
- name: import role_a's tasks
  import_tasks:
    file: "{{ playbook_dir }}/roles/role_a/tasks/main.yml"
```

Finally, we have a chorus.yml file that defines how we produce the chorus
and post-chorus. This file lives under role_a:

`roles/role_a/tasks/chorus.yml`

```
- name: chorus
  debug:
    msg: "{{ item }}"
  loop: "{{ chorus }}"

- name: post_chorus
  debug:
    msg: "{{ post_chorus }}"
```

### The vars files
Each role contains unique lyrics from "The Wizard." The roles divide the
song into a dictionary `verse`, list `chorus`, and string `post-chorus`.

`roles/role_a/vars/main.yml`

```
verse:
  - 'msg': "Misty morning, clouds in the sky"
  - 'msg': "Without warning, the wizard walks by"
  - 'msg': "Casting his shadow, weaving his spell"
  - 'msg': "Long grey cloak, tinkling bell"
chorus: 
  - "Never Talking"
  - "Justkeeps walking"
post_chorus: "Cursing his magic"
```

`roles/role_b/vars/main.yml`

```
verse:
  - 'msg': "Evil power disappears"
  - 'msg': "Demons worry when the wizard is near"
  - 'msg': "He turns tears into joy"
  - 'msg': "Everyone's happy when the wizard walks by"
post_chorus: "Spreading his magic"
```

`roles/role_c/vars/main.yml`

```
verse:
  - 'msg': "Sun is shining, clouds have gone by"
  - 'msg': "All the people give a happy sigh"
  - 'msg': "He has passed by, giving his sign"
  - 'msg': "Left all the people feeling so fine"
```

### The results
When we run the playbooks the first time:

`results.txt`

```
PLAY [apply roles] *************************************************************

TASK [Gathering Facts] *********************************************************
ok: [localhost]

TASK [role_a : What role are we executing?] ************************************
ok: [localhost] => {
    "msg": "We are running this task for role_a"
}

TASK [role_a : Print verse specified for this role.] ***************************
ok: [localhost] => (item={'msg': 'Misty morning, clouds in the sky'}) => {
    "msg": "Misty morning, clouds in the sky"
}
ok: [localhost] => (item={'msg': 'Without warning, the wizard walks by'}) => {
    "msg": "Without warning, the wizard walks by"
}
ok: [localhost] => (item={'msg': 'Casting his shadow, weaving his spell'}) => {
    "msg": "Casting his shadow, weaving his spell"
}
ok: [localhost] => (item={'msg': 'Long grey cloak, tinkling bell'}) => {
    "msg": "Long grey cloak, tinkling bell"
}

TASK [role_a : chorus] *********************************************************
ok: [localhost] => (item=Never Talking) => {
    "msg": "Never Talking"
}
ok: [localhost] => (item=Just keeps walking) => {
    "msg": "Just keeps walking"
}

TASK [role_a : post_chorus] ****************************************************
ok: [localhost] => {
    "msg": "Cursing his magic"
}

TASK [role_a : Ensure the proof folder exists] *********************************
changed: [localhost]

TASK [role_a : idempotency/proof task] *****************************************
changed: [localhost]

TASK [role_b : What role are we executing?] ************************************
ok: [localhost] => {
    "msg": "We are running this task for role_b"
}

TASK [role_b : Print verse specified for this role.] ***************************
ok: [localhost] => (item={'msg': 'Evil power disappears'}) => {
    "msg": "Evil power disappears"
}
ok: [localhost] => (item={'msg': 'Demons worry when the wizard is near'}) => {
    "msg": "Demons worry when the wizard is near"
}
ok: [localhost] => (item={'msg': 'He turns tears into joy'}) => {
    "msg": "He turns tears into joy"
}
ok: [localhost] => (item={'msg': "Everyone's happy when the wizard walks by"}) => {
    "msg": "Everyone's happy when the wizard walks by"
}

TASK [role_b : chorus] *********************************************************
ok: [localhost] => (item=Never Talking) => {
    "msg": "Never Talking"
}
ok: [localhost] => (item=Just keeps walking) => {
    "msg": "Just keeps walking"
}

TASK [role_b : post_chorus] ****************************************************
ok: [localhost] => {
    "msg": "Spreading his magic"
}

TASK [role_b : Ensure the proof folder exists] *********************************
ok: [localhost]

TASK [role_b : idempotency/proof task] *****************************************
changed: [localhost]

TASK [role_c : What role are we executing?] ************************************
ok: [localhost] => {
    "msg": "We are running this task for role_c"
}

TASK [role_c : Print verse specified for this role.] ***************************
ok: [localhost] => (item={'msg': 'Sun is shining, clouds have gone by'}) => {
    "msg": "Sun is shining, clouds have gone by"
}
ok: [localhost] => (item={'msg': 'All the people give a happy sigh'}) => {
    "msg": "All the people give a happy sigh"
}
ok: [localhost] => (item={'msg': 'He has passed by, giving his sign'}) => {
    "msg": "He has passed by, giving his sign"
}
ok: [localhost] => (item={'msg': 'Left all the people feeling so fine'}) => {
    "msg": "Left all the people feeling so fine"
}

TASK [role_c : chorus] *********************************************************
ok: [localhost] => (item=Never Talking) => {
    "msg": "Never Talking"
}
ok: [localhost] => (item=Just keeps walking) => {
    "msg": "Just keeps walking"
}

TASK [role_c : post_chorus] ****************************************************
ok: [localhost] => {
    "msg": "Spreading his magic"
}

TASK [role_c : Ensure the proof folder exists] *********************************
ok: [localhost]

TASK [role_c : idempotency/proof task] *****************************************
changed: [localhost]

PLAY RECAP *********************************************************************
localhost                  : ok=19   changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0  
```

The song has 21 lines. I am curious about how ansible is counting for `ok`. 

We register 19 `ok` tasks the play. I would expect there to be more `ok` return codes. Let's grep the results for
`ok`:

`cat results.txt | grep ok`

```
cat results.txt | grep ok

ok: [localhost]
ok: [localhost] => {
ok: [localhost] => (item={'msg': 'Misty morning, clouds in the sky'}) => {
ok: [localhost] => (item={'msg': 'Without warning, the wizard walks by'}) => {
ok: [localhost] => (item={'msg': 'Casting his shadow, weaving his spell'}) => {
ok: [localhost] => (item={'msg': 'Long grey cloak, tinkling bell'}) => {
ok: [localhost] => (item=Never Talking) => {
ok: [localhost] => (item=Just keeps walking) => {
ok: [localhost] => {
ok: [localhost] => {
ok: [localhost] => (item={'msg': 'Evil power disappears'}) => {
ok: [localhost] => (item={'msg': 'Demons worry when the wizard is near'}) => {
ok: [localhost] => (item={'msg': 'He turns tears into joy'}) => {
ok: [localhost] => (item={'msg': "Everyone's happy when the wizard walks by"}) => {
ok: [localhost] => (item=Never Talking) => {
ok: [localhost] => (item=Just keeps walking) => {
ok: [localhost] => {
ok: [localhost]
ok: [localhost] => {
ok: [localhost] => (item={'msg': 'Sun is shining, clouds have gone by'}) => {
ok: [localhost] => (item={'msg': 'All the people give a happy sigh'}) => {
ok: [localhost] => (item={'msg': 'He has passed by, giving his sign'}) => {
ok: [localhost] => (item={'msg': 'Left all the people feeling so fine'}) => {
ok: [localhost] => (item=Never Talking) => {
ok: [localhost] => (item=Just keeps walking) => {
ok: [localhost] => {
ok: [localhost]
localhost                  : ok=19   changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

```

## The Advantages of Roles
Roles give us a mechanism for creating complex interactions between objects
(tasks, variables, handlers, etc.) and artifacts (generated files, compiled
software, processed data sets, etc.)

We divide our work into reusable chunks, so we can adapt and extend configuration: as needed, or on-demand.

We could develop a ton of roles:
- common: generic Debian configuration
- xfce_desk: Configured xfce4 desktop environment
- gnome_desk: Configured gnome desktop environment
- nvidia: Configure nvidia GPU support.
- python: Configure generic Python execution environment
- pythondev: Configure python development environment
- web: configure apache and/or nginx.
- db_mysql: Configure MySQL database
- db_postgre: Configure PostgreSQL 
- apps_vscode: Configure vscode
- apps_eclipse: Configure eclipse
- apps_math: Configure mathematics applications
- apps_twod: Configure 2D design software
- apps_threed: Configure 3D design software
- libs_ai: Configure AI development libraries

