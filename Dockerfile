ARG OUTPUT_DIR=/root/output
ARG EXECUTABLE_NAME=bootstrap

FROM ghcr.io/luvemil/base-hs-lambda:cryptonite as build

# Build the dependencies
RUN mkdir -p /root/lambda-function/
RUN cd /root/lambda-function
WORKDIR /root/lambda-function/

COPY package.yaml stack.yaml /root/lambda-function/
RUN stack build --dependencies-only \
    --flag cryptonite:-use_target_attributes

# ARG PACKAGER_COMMIT_SHA=d3312736a38f7b93f87c313a8fb9c0798938b403
# RUN cd /tmp && \
#     git clone https://github.com/saurabhnanda/aws-lambda-packager.git && \
#     cd /tmp/aws-lambda-packager && \
#     git checkout ${PACKAGER_COMMIT_SHA} && \
#     stack install --resolver=${STACK_RESOLVER}

# Build the lambda
COPY . /root/lambda-function/

RUN stack build \
    --flag cryptonite:-use_target_attributes \
    --copy-bins

ARG OUTPUT_DIR

RUN mkdir -p ${OUTPUT_DIR} && \
    mkdir -p ${OUTPUT_DIR}/lib

ARG EXECUTABLE_NAME

RUN cp $(stack path --local-bin)/${EXECUTABLE_NAME} ${OUTPUT_DIR}/${EXECUTABLE_NAME}

# Finally, copying over all custom/extra libraries with the help of aws-lambda-packager
# RUN /root/.local/bin/aws-lambda-packager copy-custom-libraries \
#     -l /root/default-libraries \
#     -f ${OUTPUT_DIR}/bootstrap \
#     -o ${OUTPUT_DIR}/lib

ENTRYPOINT sh

FROM public.ecr.aws/lambda/provided:al2 as deploy

ARG EXECUTABLE_NAME

WORKDIR ${LAMBDA_RUNTIME_DIR}

ARG OUTPUT_DIR

COPY --from=build ${OUTPUT_DIR} .

RUN mv ${EXECUTABLE_NAME} bootstrap || true

CMD [ "handler" ]
