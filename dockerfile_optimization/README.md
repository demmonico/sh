#  Dockerfile optimization

Optimization `Dockerfile` step-by-step. TL;DR `v1` give best compile time and size, but has also cons - you have to build and store base image separately.

|Build target|Time, sec|Size, Mb|
|---|---|---|
|<td colspan=3>0 - [Non-optimised, single file](v0.Dockerfile): base -> dev -> prod</td>
|base	|141	|279|
|dev	|198	|496|
|prod	|228	|424|
|<td colspan=3>1 - Optimised, separate files: [base](v1.base.Dockerfile), [dev](v1.dev.Dockerfile), [prod](v1.prod.Dockerfile)</td>
|base	|152	|278|
|dev	|69	|503|
|prod	|33	|349|
|<td colspan=3>2 - [Optimised, single file](v2.Dockerfile): base -> dev -> prod</td>
|base	|145	|278|
|dev	|199	|500|
|prod	|186	|344|
|<td colspan=3>3 - [Optimised, single file](v3.Dockerfile): base -> dev -> prod, "FROM php-v3:base"</td>
|base	|138	|278|
|dev	|176	|496|
|prod	|194	|353|
|<td colspan=3>4 - [Optimised, single file](v3.Dockerfile): dev -> prod -> base, "FROM php-v4:base"</td>
|base	|223	|278|
|dev	|141	|503|
|prod	|100	|359|
