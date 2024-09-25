---
sidebar_position: 1
id: my-home-doc
slug: /
---

# How does it work?

Decidim saves users with an additional fields, to store metadatas. This field can contains whatever data we want, and is not displayed on the participant profile page. 

This module will add the capibility to configure in a simple way aditional fields for our users.
These new fields will apear in diferent pages, supported by the module: 

| Pages                                     | Supported? |
|-------------------------------------------|------------|
| Registration form                         | yes        |
| Complete invitation                       | yes        |
| Edit profile                              | yes        |
| Complete profile after OAuth registration | no         |

Once your participants add new fields to their registration, it would be sweet to re-use them for authorisation, isn't it? Well this module can do just that!
With our configuration format, we can build forms with validations that will make new authorisations. These forms can refers to user registrations fields. That enables this kind of registration flow: 

**constraint by ages**<br />
- ask for an optional birthdate on registration
- to vote on a particular place, you can create an authorisation that will require the birthdate
- when asking for authorisation, we don't ask again the birthdate if it is in the profile, and if if it not, we ask the user to fill it
