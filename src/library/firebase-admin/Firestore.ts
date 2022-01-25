import { FirebaseError } from '@firebase/util';
import { getApp, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

export type Timestamp = {
  seconds: number;
  nanoseconds: number;
};

export type DocData_ = Record<string, string>;

export type DocSnapshot_ = {
  docData: DocData_;
  createTime: Timestamp;
  updateTime: Timestamp;
  readTime: Timestamp;
};

const wrapError = (left: (a: string) => unknown) => (error: unknown) =>
  left(error instanceof FirebaseError ? error.code : 'Unknown error');

export const _initializeApp = (name: string) => initializeApp(undefined, name);

export const _createDoc =
  (left: (a: string) => unknown) =>
  (right: (a: Timestamp) => unknown) =>
  (collection: string) =>
  (docId: string) =>
  (data: DocData_): Promise<unknown> =>
    getFirestore(getApp('demo-aab'))
      .collection(collection)
      .doc(docId)
      .create(data)
      .then((result) => right(result.writeTime))
      .catch(wrapError(left));

export const _getDoc =
  (left: (a: string) => unknown) =>
  (right: (a: unknown) => unknown) =>
  (none: unknown) =>
  (just: (a: DocSnapshot_) => unknown) =>
  (collection: string) =>
  (docId: string): Promise<unknown> =>
    getFirestore(getApp('demo-aab'))
      .collection(collection)
      .doc(docId)
      .get()
      .then((result) => {
        const data = result.data();
        return right(
          data !== undefined &&
            result.createTime !== undefined &&
            result.updateTime !== undefined
            ? just({
                docData: data,
                createTime: result.createTime,
                updateTime: result.updateTime,
                readTime: result.readTime,
              })
            : none
        );
      })
      .catch(wrapError(left));
